module Babushka
  class SystemDefinitions
    def self.all_systems
      names.keys
    end
    def self.all_flavours
      names.values.map(&:keys).flatten
    end
    def self.all_names
      names.values.map(&:values).map {|s| s.map(&:values) }.flatten
    end
    def self.all_tokens
      all_systems + PkgHelper.all_manager_keys + all_flavours + all_names
    end

    def self.names
      {
        :osx => {
          :osx => {
            '10.3' => :panther,
            '10.4' => :tiger,
            '10.5' => :leopard,
            '10.6' => :snow_leopard,
            '10.7' => :lion
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
            '11.04' => :natty
          },
          :debian => {
            '4.0' => :etch,
            '5.0' => :lenny,
            '6.0' => :squeeze,
            '7.0' => :wheezy
          }
        },
        :bsd => {
          :dragonfly => {},
          :freebsd => {}
        }
      }
    end

    def self.descriptions
      {
        :osx => {
          :osx => {
            '10.3' => 'Panther',
            '10.4' => 'Tiger',
            '10.5' => 'Leopard',
            '10.6' => 'Snow Leopard',
            '10.7' => 'Lion'
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
            '11.04' => 'Natty Narwhal'
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
end
