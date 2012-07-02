require 'spec_helper'

describe Babushka::SystemProfile do
  subject {
    Babushka::SystemDetector.profile_for_host
  }

  describe SystemProfile, '#public_ip' do
    context "on OS X" do
      before {
        ShellHelpers.should_receive(:shell).with("uname -s").and_return("Darwin")
        subject.should_receive(:shell).with('netstat -nr').and_return("
Routing tables

Internet:
Destination        Gateway            Flags        Refs      Use   Netif Expire
default            10.0.1.1           UGSc           17        0     en0
10.0.1/24          link#4             UCS             3        0     en0
10.0.1.1           0:24:36:9e:85:7a   UHLWIi         16        3     en0    621
10.0.1.30          7c:c5:37:39:66:3e  UHLWIi          0     8397     en0    686
10.0.1.31          127.0.0.1          UHS             0        0     lo0
127                127.0.0.1          UCS             0        0     lo0
127.0.0.1          127.0.0.1          UH              3    43559     lo0
169.254            link#4             UCS             0        0     en0

Internet6:
Destination                             Gateway                         Flags         Netif Expire
::1                                     link#1                          UHL             lo0
fe80::%lo0/64                           fe80::1%lo0                     UcI             lo0
fe80::1%lo0                             link#1                          UHLI            lo0
fe80::%en0/64                           link#4                          UCI             en0
fe80::21f:f3ff:fe05:4659%en0            0:1f:f3:5:46:59                 UHLWIi          en0
fe80::223:6cff:fe82:3451%en0            0:23:6c:82:34:51                UHLWIi          en0
fe80::62c5:47ff:fe03:5238%en0           60:c5:47:3:52:38                UHLWIi          en0
fe80::62c5:47ff:fe03:5b6a%en0           60:c5:47:3:5b:6a                UHLI            lo0
fe80::6aa8:6dff:fe08:6ea2%en0           68:a8:6d:8:6e:a2                UHLWIi          en0
fe80::e6ce:8fff:fe17:53c%en0            e4:ce:8f:17:5:3c                UHLWIi          en0
ff01::%lo0/32                           fe80::1%lo0                     UmCI            lo0
ff01::%en0/32                           link#4                          UmCI            en0
ff02::%lo0/32                           fe80::1%lo0                     UmCI            lo0
ff02::%en0/32                           link#4                          UmCI            en0
ff02::fb%en0                            link#4                          UHmW3I          en0    350
        ")
        subject.should_receive(:shell).with('ifconfig', 'en0').and_return("
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 60:c5:47:03:5b:6a
	inet6 fe80::62c5:47ff:fe03:5b6a%en0 prefixlen 64 scopeid 0x4
	inet 10.0.1.31 netmask 0xffffff00 broadcast 10.0.1.255
	media: autoselect
	status: active
        ")
      }
      it "should return the correct IP" do
        subject.public_ip.should == '10.0.1.31'
      end
    end

    context "on Linux" do
      before {
        ShellHelpers.should_receive(:shell).with("uname -s").and_return("Linux")
        subject.should_receive(:shell).with('netstat -nr').and_return("
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
49.156.17.0     0.0.0.0         255.255.255.0   U         0 0          0 eth0
10.0.0.0        0.0.0.0         255.0.0.0       U         0 0          0 eth1
0.0.0.0         49.156.17.1     0.0.0.0         UG        0 0          0 eth0
        ")
        subject.should_receive(:shell).with('ifconfig', 'eth0').and_return("
eth0      Link encap:Ethernet  HWaddr 00:16:31:9c:11:ad
          inet addr:49.156.17.173  Bcast:49.156.17.255  Mask:255.255.255.0
          inet6 addr: fe80::216:31ff:fe9c:11ad/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:1314347 errors:0 dropped:0 overruns:0 frame:0
          TX packets:743081 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1044706658 (1.0 GB)  TX bytes:96454071 (96.4 MB)
          Interrupt:16
        ")
      }
      it "should return the correct IP" do
        subject.public_ip.should == '49.156.17.173'
      end
    end

  end

end
