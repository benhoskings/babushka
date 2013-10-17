# coding: utf-8

module Babushka
  class SystemDefinition

    def self.all_systems
      CODENAMES.keys
    end

    def self.all_flavours
      CODENAMES.values.map(&:keys).flatten
    end

    def self.all_names
      CODENAMES.values.map(&:values).map {|s| s.map(&:values) }.flatten
    end

    def self.all_tokens
      all_systems + PkgHelper.all_manager_keys + all_flavours + all_names
    end

    attr_reader :system, :flavour, :release

    def initialize system, flavour, release
      @system, @flavour, @release = system, flavour, release
    end

    def codename
      (CODENAMES[system][flavour] || {})[release]
    end

    def codename_str
      (DESCRIPTIONS[system][flavour] || {})[release]
    end

    CODENAMES = {
      :osx => {
        :osx => {
          '10.3' => :panther,
          '10.4' => :tiger,
          '10.5' => :leopard,
          '10.6' => :snow_leopard,
          '10.7' => :lion,
          '10.8' => :mountain_lion,
          '10.9' => :mavericks
        }
      },
      :linux => {
        :ubuntu => {
          '4.10'  => :warty,
          '5.04'  => :hoary,
          '5.10'  => :breezy,
          '6.06'  => :dapper,
          '6.10'  => :edgy,
          '7.04'  => :feisty,
          '7.10'  => :gutsy,
          '8.04'  => :hardy,
          '8.10'  => :intrepid,
          '9.04'  => :jaunty,
          '9.10'  => :karmic,
          '10.04' => :lucid,
          '10.10' => :maverick,
          '11.04' => :natty,
          '11.10' => :oneiric,
          '12.04' => :precise,
          '12.10' => :quantal,
          '13.04' => :raring,
          '13.10' => :saucy
        },
        :debian => {
          '4.0' => :etch,
          '5.0' => :lenny,
          '6.0' => :squeeze,
          '7.0' => :wheezy,
          '7.1' => :wheezy, # Temporary, until these are parsed by major
          '7.2' => :wheezy, # version.
          '8.0' => :jessie
        },
        :redhat => {
          '3' => :taroon,
          '4' => :nahant,
          '5' => :tikanga,
          '6' => :santiago
        },
        :fedora => {
          '14' => :laughlin,
          '15' => :lovelock,
          '16' => :verne,
          '17' => :beefy,
          '18' => :spherical,
          '19' => :schrodinger
        },
        :arch => {}
      },
      :bsd => {
        :dragonfly => {},
        :freebsd => {}
      }
    }

    DESCRIPTIONS = {
      :osx => {
        :osx => {
          '10.3' => 'Panther',
          '10.4' => 'Tiger',
          '10.5' => 'Leopard',
          '10.6' => 'Snow Leopard',
          '10.7' => 'Lion',
          '10.8' => 'Mountain Lion',
          '10.9' => 'Mavericks'
        }
      },
      :linux => {
        :ubuntu => {
          '4.10'  => 'Warty Warthog',
          '5.04'  => 'Hoary Hedgehog',
          '5.10'  => 'Breezy Badger',
          '6.06'  => 'Dapper Drake',
          '6.10'  => 'Edgy Eft',
          '7.04'  => 'Feisty Fawn',
          '7.10'  => 'Gutsy Gibbon',
          '8.04'  => 'Hardy Heron',
          '8.10'  => 'Intrepid Ibex',
          '9.04'  => 'Jaunty Jackalope',
          '9.10'  => 'Karmic Koala',
          '10.04' => 'Lucid Lynx',
          '10.10' => 'Maverick Meerkat',
          '11.04' => 'Natty Narwhal',
          '11.10' => 'Oneiric Ocelot',
          '12.04' => 'Precise Pangolin',
          '12.10' => 'Quantal Quetzal',
          '13.04' => 'Raring Ringtail',
          '13.10' => 'Saucy Salamander'
        },
        :redhat => {
          '3' => 'Taroon',
          '4' => 'Nahant',
          '5' => 'Tikanga',
          '6' => 'Santiago'
        },
        :fedora => {
          '14' => 'Laughlin',
          '15' => 'Lovelock',
          '16' => 'Verne',
          '17' => 'Beefy Miracle',
          '18' => 'Spherical Cow',
          '19' => "Schrödinger's Cat"
        }
      },
      :bsd => {
        :dragonfly => {},
        :freebsd => {}
      }
    }
  end
end
