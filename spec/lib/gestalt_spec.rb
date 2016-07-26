require 'spec_helper'

describe Gestalt do
  let(:file) { %Q{{"test":{"attr":{"inner":{"value":"value"}}}}} }
  let(:config_file_path) { "path/to/config/test.json" }
  let(:string_io) { StringIO.new(file) }
  let(:env) { "test" }
  let(:klass) { Class.new.include(Gestalt) }

  before do
    allow(Dir).to receive(:[]).and_return([config_file_path])
    allow(File).to receive(:open).and_return(string_io)
  end
  
  subject { klass.new }

  it 'has a version number' do
    expect(Gestalt::VERSION).not_to be nil
  end 
  
  describe 'mixin' do
    context 'as an extension' do
      subject { Class.new.extend(Gestalt) }

      it 'stores the gestalt configuration in the "gestalt" method' do
        expect(subject.gestalt).to be_kind_of(Gestalt::Store)
      end

      it 'responds to #load_environment as a class method' do
        expect(subject).to respond_to(:load_environment)
      end

      describe 'the gestalt default configuration' do
        subject { Class.new.extend(Gestalt).gestalt }

        it 'has the default config path' do
          expect(subject.config_path).to eq(Gestalt::DEFAULT_CONFIG_PATH)
        end
      end
    end

    context 'as an inclusion' do
      subject { Class.new.include(Gestalt) }

      it 'stores the gestalt configuration in the "gestalt" method' do
        expect(subject.gestalt).to be_kind_of(Gestalt::Store)
      end

      it 'responds to #load_environment as an instance method' do
        expect(subject.new).to respond_to(:load_environment)
      end

      describe 'the gestalt default configuration' do
        subject { Class.new.include(Gestalt).gestalt }

        it 'has the default config path' do
          expect(subject.config_path).to eq(Gestalt::DEFAULT_CONFIG_PATH)
        end
      end
    end
  end

  describe '#load_environment' do
    context 'when config path has a trailing slash' do
      before do
        subject.class.gestalt.config_path = 'path/to/config/path/'
      end

      it 'loads from the correct directory' do
        expect(Dir).to receive(:[]).with('path/to/config/path/*')
        subject.load_environment(env)
      end
    end

    context 'when extension is supported' do
      before do
        subject.load_environment(env)
      end

      context 'with json file' do
        # See beginning of spec definition for JSON example
        
        it 'loads the configuration' do
          expect(subject.configuration).to be
        end
      end

      context 'with yaml file' do
        let(:config_file_path) { "path/to/config/test.yaml" }
        let(:file) { %Q{test:\n attr:\n  inner:\n   value: value\n} }
        
        it 'loads the configuration' do
          expect(subject.configuration).to be
        end
      end

      context 'when environment is not found' do
        it 'raises an UndefinedEnvironmentError error' do
          expect {
            subject.load_environment('unknown')
          }
          .to raise_error(Gestalt::UndefinedEnvironmentError,
                          "Environment 'unknown' not found in #{config_file_path}")
        end
      end
    end

    context 'when extension is not supported' do
      let(:config_file_path) { 'path/to/config/test.txt' }

      it 'raises an UnsupportedExtensionError' do
        expect {
          subject.load_environment(env)
        }.to raise_error(Gestalt::UnsupportedExtensionError,
                         "Extension '.txt' is not supported")
      end
    end
  end

  describe '#configuration' do
    before do
      subject.load_environment(env)
    end

    it 'returns a Store instance' do
      expect(subject.configuration).to be_kind_of(Gestalt::Store)
    end

    describe 'store' do
      it 'stores the configuration from the file' do
        expect(subject.configuration['test']['attr']['inner']['value'])
          .to eq('value')
      end
    end

    describe 'alias' do
      it 'is identical to #configuration' do
        expect(subject.configuration).to be(subject.config)
      end
    end
  end

end
