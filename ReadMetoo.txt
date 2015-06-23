1，配置好服务器和client 网络
内网和外网,include dns

2，在客户端

yum install -y git
git clone https://github.com/inevity/autodtma.git RUNs

3，在客户端 进入RUNs／misc,
执行./setup
进行一系列设置后服务器和client机器会先后重启
4,在客户端，待两者重启后
/root/RUNs/misc/rebootafter.sh

其中编译squid（ucache）编译htterpf：，重启nginx，squid。
同时在客户端 生成所测试的文件（根据Core.sh和测试的目的）
例如
cd /usr/share/nginx/html/
dd if=/dev/zero of=612B bs=1 count=612

6，
  利用iperf进行网络验证
  手动进行httperf测试，观察squid是否配置好,squidlog -a 是否hit
7，根据所要测试的文件大小，修改RUNs下的filemap和Core.sh 中第35行的文件列表，开始测试
比如
ls /usr/share/nginx/html/ -la|egrep '612B|1KB|64KB|128KB|192KB|256KB|320KB|384KB|
448KB|512KB|576KB|640KB|768KB|1024KB' |sort -k +5n |awk '{print $5 " " $9}' > ~/RUNs/filemap
这个命令，生成一个filemap。
修改Core.sh 中第35行的文件列表，比如要测试这612B，1KB的文件，就改为for 612 1024.注意这里for后面是以字节为单位，
就是filemap的第一列的值。


Core.sh
./Core.sh 1Kto1MB ./misc/rates.txt1KB-1MB www.myweb.com 80 index.html 40000 0 0 0
采用4w。

参数依次是测试名，测试速率，测试站点，测试端口，测试url，连接数，是否会话，
是否要探测prof，探测类别（我们暂时是1，perf）





注：
select rate for file 
revert to svn
test replicate problem
repeate run the script
manual operate is 1 2 6 ,we should  select ratefile and filesize to run 7.

