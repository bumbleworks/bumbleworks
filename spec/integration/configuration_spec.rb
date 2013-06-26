describe Bumbleworks::Configuration do
  let(:specified_app_path) { File.join(fixtures_path, 'apps', 'with_specified_directories') }
  let(:default_app_path) { File.join(fixtures_path, 'apps', 'with_default_directories') }
  let(:specified_initializer) { File.join(specified_app_path, 'config_initializer.rb') }
  let(:default_initializer) { File.join(default_app_path, 'config_initializer.rb') }

  describe '#root' do
    it 'returns configured root' do
      load default_initializer
      Bumbleworks.root.should == default_app_path
    end
  end

  describe '#definitions_directory' do
    it 'returns specified directory when set in configuration' do
      load specified_initializer
      Bumbleworks.definitions_directory.should == File.join(specified_app_path, 'specific_directory', 'definitions')
    end

    it 'returns default directory when not set in configuration' do
      load default_initializer
      Bumbleworks.definitions_directory.should == File.join(default_app_path, 'lib', 'bumbleworks', 'process_definitions')
    end
  end

  describe '#participants_directory' do
    it 'returns specified directory when set in configuration' do
      load specified_initializer
      Bumbleworks.participants_directory.should == File.join(specified_app_path, 'specific_directory', 'participants')
    end

    it 'returns default directory when not set in configuration' do
      load default_initializer
      Bumbleworks.participants_directory.should == File.join(default_app_path, 'lib', 'bumbleworks', 'participants')
    end
  end
end
