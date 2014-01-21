module Bumbleworks
  class ParticipantRegistration
    class << self
      # @public
      # Autoload all participant classes defined in files in the
      # participants_directory.  The symbol for autoload comes from the
      # camelized version of the filename, so this method is dependent on
      # following that convention.  For example, file `goat_challenge.rb`
      # should define `GoatChallenge`.
      #
      def autoload_all(options = {})
        if directory = options[:directory] || Bumbleworks.participants_directory
          Bumbleworks::Support.all_files(directory, :camelize => true).each do |path, name|
            Object.autoload name.to_sym, path
          end
        end
      end

      def register!(options = {})
        if file = options[:file] || Bumbleworks.participant_registration_file
          Kernel.load file
        else
          Bumbleworks.register_default_participants
        end
      end
    end
  end
end