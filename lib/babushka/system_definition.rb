module Babushka
  class SystemDefinition

    def self.all_systems
      NAMES.keys
    end

    def self.all_flavours
      NAMES.values.map(&:keys).flatten
    end

    def self.all_names
      NAMES.values.map(&:values).map {|s| s.map(&:values) }.flatten
    end

    def self.all_tokens
      all_systems + PkgHelper.all_manager_keys + all_flavours + all_names
    end

    attr_reader :system, :flavour, :release

    def initialize system, flavour, release
      @system, @flavour, @release = system, flavour, release
    end

    def name
      (NAMES[system][flavour] || {})[release]
    end

    def name_str
      (DESCRIPTIONS[system][flavour] || {})[release]
    end

    NAMES = {
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
          '12.04' => :precise
        },
        :debian => {
          '4.0' => :etch,
          '5.0' => :lenny,
          '6.0' => :squeeze,
          '7.0' => :wheezy
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
          '12.04' => 'Precise Pangolin'
        },
        :debian => {
          '5.0.4' => 'Lenny'
        }
      },
      :bsd => {
        :dragonfly => {},
        :freebsd => {}
      }
    }
  end
end
