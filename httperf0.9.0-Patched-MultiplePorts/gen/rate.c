/*
    httperf -- a tool for measuring web server performance
    Copyright (C) 2000  Hewlett-Packard Company
    Contributed by David Mosberger-Tang <davidm@hpl.hp.com>

    This file is part of httperf, a web server performance measurment
    tool.

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
    02111-1307 USA
*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <httperf.h>
#include <event.h>
#include <object.h>
#include <rate.h>
#include <timer.h>

/* By pushing the random number generator state into the caller via
   the xsubi array below, we gain some test repeatability.  For
   example, let us say one generator was starting sessions, and a
   different generator was controlling requests within a session.  If
   both processes were sharing the same random number generator, then
   a premature session termination would change the subsequent session
   arrival spacing.  */

static int iat_index;

static Time
next_arrival_time_det (Rate_Generator *rg)
{
  return rg->rate->mean_iat;
}

static Time
next_arrival_time_uniform (Rate_Generator *rg)
{
  Time lower, upper;

  lower = rg->rate->min_iat;
  upper = rg->rate->max_iat;

  return lower + (upper - lower)*erand48 (rg->xsubi);
}

static Time
next_arrival_time_exp (Rate_Generator *rg)
{
  Time mean = rg->rate->mean_iat;
  return -mean*log (1.0 - erand48 (rg->xsubi));
}

static Time
next_arrival_time_specified (Rate_Generator *rg)
{
  Time next = (Time)iat_values[iat_index];
  iat_index++;
  if(iat_index==total_iat_values)iat_index=0;
  return next;
}


static void
tick (Timer *t, Any_Type arg)
{
  Time delay, now = timer_now ();
  Rate_Generator *rg = arg.vp;

  rg->timer = 0;
  if (rg->done)
    return;

  while (now > rg->next_time)
    {
      delay = (*rg->next_interarrival_time) (rg);
	/*fprintf (stderr, "next arrival delay = %.4f\n", delay);*/
      if (verbose > 2)
	fprintf (stderr, "next arrival delay = %.4f\n", delay);
      rg->next_time += delay;
      rg->done = ((*rg->tick) (rg->arg) < 0);
      if (rg->done)
	return;
    }
  rg->timer = timer_schedule ((Timer_Callback) tick, arg, rg->next_time - now);
}

static void
done (Event_Type type, Object *obj, Any_Type reg_arg, Any_Type call_arg)
{
  Rate_Generator *rg = reg_arg.vp;

  if (rg->done)
    return;
  rg->done = ((*rg->tick) (rg->arg) < 0);
}

void
rate_generator_start (Rate_Generator *rg, Event_Type completion_event)
{
  Time (*func) (struct Rate_Generator *rg);
  Any_Type arg;
  Time delay;

  /* Initialize random number generator with the init values here, all
     rate generators (although independent) will follow the same
     sequence of random values.  We factor in the client's id to make
     sure no two machines running httperf generate identical random
     numbers.  May want to pass these values as args to
     rate_generator_start in the future.  */
  rg->xsubi[0] = 0x1234 ^ param.client.id;
  rg->xsubi[1] = 0x5678 ^ (param.client.id << 8);
  rg->xsubi[2] = 0x9abc ^ ~param.client.id;
  
  arg.vp = rg;
  if (rg->rate->rate_param > 0.0)
    {
      switch (rg->rate->dist)
	{
	case DETERMINISTIC: func = next_arrival_time_det; break;
	case UNIFORM:	    func = next_arrival_time_uniform; break;
	case EXPONENTIAL:   func = next_arrival_time_exp; break;
        case SPECIFIED:     func = next_arrival_time_specified; iat_index=0; break;
	default:
	  fprintf (stderr, "%s: unrecognized interarrival distribution %d\n",
		   prog_name, rg->rate->dist);
	  exit (-1);
	}
      rg->next_interarrival_time = func;
      delay = (*func) (rg);
      /* bias `next time' so that timeouts are rounded to the closest
         tick: */
      rg->next_time = timer_now () + delay;
      rg->timer = timer_schedule ((Timer_Callback) tick, arg, delay);
    }
  else
    /* generate callbacks sequentially: */
    event_register_handler (completion_event, done, arg);

  rg->start = timer_now ();
  rg->done = ((*rg->tick) (rg->arg) < 0);
}

void
rate_generator_stop (Rate_Generator *rg)
{
  if (rg->timer)
    {
      timer_cancel (rg->timer);
      rg->timer = 0;
    }
  rg->done = 1;
}
