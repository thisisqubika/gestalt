require 'spec_helper'

describe Gestalt do
  let(:file) { %Q{{"test":{"attr":{"inner":{"value":"value"}}}}} }
  let(:config_file_path) { 'path/to/config/test.json' }
  let(:string_io) { StringIO.new(file) }
  let(:env) { 'test' }
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

      it 'responds to #parse_configuration as a class method' do
        expect(subject).to respond_to(:parse_configuration)
      end

      describe 'the gestalt default configuration' do
        subject { Class.new.extend(Gestalt).gestalt }

        it 'has the default config path' do
          expect(subject.config_path).to eq(Gestalt::CONFIG_PATH)
        end

        it 'has the default flag set for unsupported extensions' do
          expect(subject.ignore_unsupported_extensions).to eq(Gestalt::IGNORE_UNSUPPORTED_EXTENSIONS)
        end
      end
    end

    context 'as an inclusion' do
      subject { Class.new.include(Gestalt) }

      it 'stores the gestalt configuration in the "gestalt" method' do
        expect(subject.gestalt).to be_kind_of(Gestalt::Store)
      end

      it 'responds to #parse_configuration as an instance method' do
        expect(subject.new).to respond_to(:parse_configuration)
      end

      describe 'the gestalt default configuration' do
        subject { Class.new.include(Gestalt).gestalt }

        it 'has the default config path' do
          expect(subject.config_path).to eq(Gestalt::CONFIG_PATH)
        end

        it 'has the default flag set for unsupported extensions' do
          expect(subject.ignore_unsupported_extensions).to eq(Gestalt::IGNORE_UNSUPPORTED_EXTENSIONS)
        end
      end
    end
  end

  describe '#parse_configuration' do
    it 'stores the root key' do
      subject.parse_configuration(env)
      expect(subject.class.gestalt.root_key).to eq(env)
    end

    context 'when config path has a trailing slash' do
      before do
        subject.class.gestalt.config_path = 'path/to/config/path/'
      end

      it 'loads from the correct directory' do
        expect(Dir).to receive(:[]).with('path/to/config/path/*')
        subject.parse_configuration(env)
      end
    end

    context 'when extension is supported' do
      before do
        subject.parse_configuration(env)
      end

      context 'with json file' do
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
    end

    context 'when extension is not supported' do
      let(:config_file_path) { 'path/to/config/test.txt' }

      context 'when setting is to ignore the file' do
        it 'does not raise an error' do
          expect {
            subject.parse_configuration(env)
          }.to_not raise_error
        end
      end

      context 'when setting is to raise the error' do
        before do
          subject.class.gestalt.ignore_unsupported_extensions = false
        end

        it 'raises an UnsupportedExtensionError' do
          expect {
            subject.parse_configuration(env)
          }.to raise_error(Gestalt::UnsupportedExtensionError,
                           'Extension \'.txt\' is not supported')
        end
      end
    end

    context 'when root is not found' do
      it 'raises an RootKeyNotFoundError error' do
        expect {
          subject.parse_configuration('unknown')
        }.to raise_error(Gestalt::RootKeyNotFoundError,
                         "Key 'unknown' not found at root of #{config_file_path}")
      end
    end

    context 'when root is not passed' do
      before do
        subject.parse_configuration
      end

      it 'stores the root key as nil' do
        expect(subject.class.gestalt.root_key).to be_nil
      end

      it 'stores configuration from the root key' do
        expect(subject.config.test).to be
      end
    end

    context 'when block is passed' do
      it 'calls the passed block at the end' do
        expect(subject.parse_configuration(env) { 'finished' }).to eq('finished')
      end
    end
  end

  describe '#configuration' do
    before do
      subject.parse_configuration(env)
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
