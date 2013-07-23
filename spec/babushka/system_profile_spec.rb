require 'spec_helper'

describe Babushka::SystemProfile do
  let(:profile) {
    Babushka::SystemDetector.profile_for_host
  }

  describe 'names' do

    def info_for p
      [p.system, p.flavour, p.release, p.version, p.name]
    end

    def info_strs_for p
      [p.system_str, p.flavour_str, p.name_str]
    end

    describe 'on an unknown system' do
      let(:profile) { UnknownSystem.new }

      it "should report correct name and version info" do
        info_for(profile).should == [:unknown, :unknown, 'unknown', 'unknown', :unknown]
      end
      it "should report correct info strings" do
        info_strs_for(profile).should == ['Unknown', 'Unknown', 'Unknown']
      end
      it "should be described correctly" do
        profile.description.should == 'Unknown system'
      end
    end

    describe 'on an OS X box' do
      let(:profile) { OSXSystemProfile.new }
      before { profile.stub(:get_version_info).and_return("ProductName:  Mac OS X\nProductVersion: 10.8.4\nBuildVersion: 12E55") }

      it "should have correct system info" do
        info_for(profile).should == [:osx, :osx, '10.8', '10.8.4', :mountain_lion]
      end
      it "should have correct version info" do
        info_strs_for(profile).should == ['Mac OS X', 'Mac OS X', 'Mountain Lion']
      end
      it "should have the right description" do
        profile.description.should == 'Mac OS X 10.8.4 (Mountain Lion)'
      end
    end

    describe 'on a BSD box' do
      let(:profile) { BSDSystemProfile.new }
      before { profile.stub(:shell).with('uname -r').and_return("1.2.3") }

      it "should have correct system info" do
        info_for(profile).should == [:bsd, :unknown, '1.2', '1.2.3', nil]
      end
      it "should have correct version info" do
        info_strs_for(profile).should == ['BSD', 'Unknown', nil]
      end
      it "should be described correctly" do
        profile.description.should == 'Unknown BSD 1.2.3'
      end

      describe 'on a FreeBSD box' do
        let(:profile) { FreeBSDSystemProfile.new }
        before { profile.stub(:shell).with('uname -r').and_return("9.0-RELEASE") }

        it "should have correct system info" do
          info_for(profile).should == [:bsd, :freebsd, '9.0-RELEASE', '9.0-RELEASE', nil]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['BSD', 'FreeBSD', nil]
        end
        it "should be described correctly" do
          profile.description.should == 'FreeBSD 9.0-RELEASE'
        end
      end

      describe 'on a DragonFly box' do
        let(:profile) { DragonFlySystemProfile.new }
        before { profile.stub(:shell).with('uname -r').and_return("1.2.3") }

        it "should have correct system info" do
          info_for(profile).should == [:bsd, :dragonfly, '1.2', '1.2.3', nil]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['BSD', 'DragonFly', nil]
        end
        it "should be described correctly" do
          profile.description.should == 'DragonFly BSD 1.2.3'
        end
      end
    end

    describe 'on a Linux box' do
      let(:profile) { LinuxSystemProfile.new }

      it "should have correct system info" do
        info_for(profile).should == [:linux, :unknown, nil, nil, nil]
      end
      it "should have correct version info" do
        info_strs_for(profile).should == ['Linux', 'Unknown', nil]
      end
      it "should be described correctly" do
        profile.description.should == 'Unknown Linux'
      end

      context 'on a Debian 7 box' do
        let(:profile) { DebianSystemProfile.new }
        before { profile.stub(:get_version_info).and_return(%Q{7.0}) }

        it "should have correct name and version info" do
          info_for(profile).should == [:linux, :debian, "7.0", "7.0", :wheezy]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['Linux', 'Debian', 'wheezy']
        end
        it "should be described correctly" do
          profile.description.should == 'Debian Linux 7.0 (wheezy)'
        end
      end

      context 'on a Debian 6 box' do
        let(:profile) { DebianSystemProfile.new }
        before { profile.stub(:get_version_info).and_return(%Q{6.0.4}) }

        it "should have correct name and version info" do
          info_for(profile).should == [:linux, :debian, "6.0", "6.0.4", :squeeze]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['Linux', 'Debian', 'squeeze']
        end
        it "should be described correctly" do
          profile.description.should == 'Debian Linux 6.0.4 (squeeze)'
        end
      end

      context 'on an Ubuntu box' do
        let(:profile) { UbuntuSystemProfile.new }
        before { profile.stub(:get_version_info).and_return(%Q{DISTRIB_ID=Ubuntu\nDISTRIB_RELEASE=12.04\nDISTRIB_CODENAME=precise\nDISTRIB_DESCRIPTION="Ubuntu 12.04.2 LTS"}) }

        it "should have correct name and version info" do
          info_for(profile).should == [:linux, :ubuntu, "12.04", "12.04", :precise]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['Linux', 'Ubuntu', 'Precise Pangolin']
        end
        it "should be described correctly" do
          profile.description.should == 'Ubuntu Linux 12.04 (Precise Pangolin)'
        end
      end

      context 'on a Redhat box' do
        let(:profile) { RedhatSystemProfile.new }
        before { profile.stub(:get_version_info).and_return("Red Hat Enterprise Linux Server release 6.4 (Santiago)") }

        it "should have correct system info" do
          info_for(profile).should == [:linux, :redhat, "6", "6.4", :santiago]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['Linux', 'Red Hat', 'Santiago']
        end
        it "should be described correctly" do
          profile.description.should == 'Red Hat Linux 6.4 (Santiago)'
        end
      end

      context 'on a CentOS box' do
        let(:profile) { CentOSSystemProfile.new }
        before { profile.stub(:get_version_info).and_return("CentOS release 6.4 (Final)") }

        it "should have correct system info" do
          info_for(profile).should == [:linux, :centos, "6", "6.4", nil]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['Linux', 'CentOS', nil]
        end
        it "should be described correctly" do
          profile.description.should == 'CentOS Linux 6.4'
        end
      end

      context 'on a Fedora box' do
        let(:profile) { FedoraSystemProfile.new }
        before { profile.stub(:get_version_info).and_return("Fedora release 18 (Spherical Cow)") }

        it "should report correct name and version info" do
          info_for(profile).should == [:linux, :fedora, "18", "18", :spherical]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['Linux', 'Fedora', 'Spherical Cow']
        end
        it "should be described correctly" do
          profile.description.should == 'Fedora Linux 18 (Spherical Cow)'
        end
      end

      context 'on an Arch box' do
        let(:profile) { ArchSystemProfile.new }

        it "should report correct name and version info" do
          info_for(profile).should == [:linux, :arch, nil, nil, nil]
        end
        it "should have correct version info" do
          info_strs_for(profile).should == ['Linux', 'Arch', nil]
        end
        it "should be described correctly" do
          profile.description.should == 'Arch Linux'
        end
      end
    end
  end

  describe '#cpu_type' do
    it "should return the type reported by `uname`" do
      profile.should_receive(:shell).with('uname -m').and_return('x86')
      profile.cpu_type.should == 'x86'
    end
    it "should substitute 'x86_64' for 'amd64'" do
      profile.should_receive(:shell).with('uname -m').and_return('amd64')
      profile.cpu_type.should == 'x86_64'
    end
  end

  describe '#cpus' do
    it "should work on OS X" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("Darwin")
      profile.should_receive(:shell).with('sysctl -n hw.ncpu').and_return("4")
      profile.cpus.should == 4
    end
    it "should work on Linux" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("Linux")
      profile.should_receive(:shell).with("cat /proc/cpuinfo | grep '^processor\\b' | wc -l").and_return("    4")
      profile.cpus.should == 4
    end
    it "should work on FreeBSD" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("FreeBSD")
      profile.should_receive(:shell).with('sysctl -n hw.ncpu').and_return("4")
      profile.cpus.should == 4
    end
    it "should work on DragonFly" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("DragonFly")
      profile.should_receive(:shell).with('sysctl -n hw.ncpu').and_return("4")
      profile.cpus.should == 4
    end
  end

  describe '#total_memory' do
    it "should work on OS X" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("Darwin")
      profile.should_receive(:shell).with('sysctl -n hw.memsize').and_return("4294967296")
      profile.total_memory.should == 4294967296
    end
    it "should work on Linux" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("Linux")
      profile.should_receive(:shell).with('free -b').and_return("             total       used       free     shared    buffers     cached
Mem:    1039704064  930856960  108847104          0    2244608  751648768
-/+ buffers/cache:  176963584  862740480
Swap:            0          0          0
")
      profile.total_memory.should == 1039704064
    end
    it "should work on FreeBSD" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("FreeBSD")
      profile.should_receive(:shell).with('sysctl -n hw.realmem').and_return("242647040")
      profile.total_memory.should == 242647040
    end
    it "should work on DragonFly" do
      ShellHelpers.should_receive(:shell).with("uname -s").and_return("DragonFly")
      profile.should_receive(:shell).with('sysctl -n hw.physmem').and_return("242647040")
      profile.total_memory.should == 242647040
    end
  end

  describe '#public_ip' do
    context "on OS X" do
      before {
        ShellHelpers.should_receive(:shell).with("uname -s").and_return("Darwin")
        profile.should_receive(:shell).with('netstat -nr').and_return("
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
        profile.should_receive(:shell).with('ifconfig', 'en0').and_return("
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 60:c5:47:03:5b:6a
	inet6 fe80::62c5:47ff:fe03:5b6a%en0 prefixlen 64 scopeid 0x4
	inet 10.0.1.31 netmask 0xffffff00 broadcast 10.0.1.255
	media: autoselect
	status: active
        ")
      }
      it "should return the correct IP" do
        profile.public_ip.should == '10.0.1.31'
      end
    end

    context "on Linux" do
      before {
        ShellHelpers.should_receive(:shell).with("uname -s").and_return("Linux")
        profile.should_receive(:shell).with('netstat -nr').and_return("
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
49.156.17.0     0.0.0.0         255.255.255.0   U         0 0          0 eth0
10.0.0.0        0.0.0.0         255.0.0.0       U         0 0          0 eth1
0.0.0.0         49.156.17.1     0.0.0.0         UG        0 0          0 eth0
        ")
        profile.should_receive(:shell).with('ifconfig', 'eth0').and_return("
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
        profile.public_ip.should == '49.156.17.173'
      end
    end

  end

end
