require 'spec_helper'

describe Gestalt::Store do
  let(:configuration) { {'key' => 'value'} }

  subject { described_class.new(configuration, 'test') }

  describe '.new' do
    it 'instantiates without parameters' do
      expect(described_class.new).to be_kind_of(Gestalt::Store)
    end
  end

  describe '#[]' do
    context 'when key is included' do
      it 'returns the value stored in the key' do
        expect(subject['key']).to eq('value')
      end

      context 'when value is a hash' do
        let(:configuration) { {'key' => {'inner_key' => 'value'}} }

        it 'returns a new Store instance' do
          expect(subject['key']).to be_kind_of(described_class)
        end

        it 'returns a Store containing the inner hash' do
          expect(subject['key']['inner_key']).to eq('value')
        end
      end

      context 'when key is an object other than string or symbol' do
        let(:configuration) { {nil => 'value'} }

        it 'allows access using any object' do
          expect(subject[nil]).to eq('value')
        end
      end
    end

    context 'when key is not included' do
      it 'raises a KeyNotFoundError error' do
        expect {
          subject['not_included']
        }.to raise_error(Gestalt::KeyNotFoundError, 'Key "not_included" is not present at "test"' )
      end
    end

  end

  describe '#[]=' do
    it 'stores a key and value' do
      subject['new_key'] = 'new_value'
      expect(subject['new_key']).to eq('new_value')
    end
  end

  describe '#breadcrumbs' do
    let(:configuration) { {'child' => {'key' => 'value'}} }
    let(:parent) { described_class.new(configuration, 'parent') }

    subject { described_class.new(configuration['child'], 'child', parent) }

    it 'returns the breadrcumbs in the expected format' do
      expect(subject.breadcrumbs).to eq('"parent" -> "child"')
    end

    context 'when subject is root' do
      subject { described_class.new(configuration, 'parent') }

      it 'returns the key name' do
        expect(subject.breadcrumbs).to eq('"parent"')
      end

      context 'when key name is not present' do
        subject { described_class.new(configuration) }

        it 'returns a generic root name' do
          expect(subject.breadcrumbs).to eq(described_class::ROOT.inspect)
        end
      end
    end

    context 'when key name is an object' do
      let(:object) { Object.new }
      let(:configuration) { {object => {'key' => 'value'}} }

      subject { described_class.new(configuration[object], object, parent) }

      it 'returns breadcrumbs with the string representation of the object' do
        expect(subject.breadcrumbs).to eq("\"parent\" -> #{object.to_s}")
      end
    end

  end

  describe 'missing methods' do
    describe 'without arguments' do
      context 'when there\'s a string key with the method name for each argument' do
        let(:configuration) { {'key_1' => {'key_2' => {'key_3' => 'value'}}} }

        it 'allows navigation through method chaining' do
          expect(subject.key_1.key_2.key_3).to be(configuration['key_1']['key_2']['key_3'])
        end

        it 'allows interchangeable access' do
          expect(subject.key_1['key_2'].key_3).to be(configuration['key_1']['key_2']['key_3'])
        end
      end

      context 'when methods reference symbol keys' do
        let(:configuration) { {'key_1' => {key_2: {key_3: 'value'}}} }

        it 'raises an error' do
          expect {
            subject.key_1.key_2.key_3
          }.to raise_error(Gestalt::KeyNotFoundError, 'Key "key_2" is not present at "test" -> "key_1"')
        end
      end

      context 'when a block is given' do
        it 'calls the block and assigns the result' do
          expect { subject.key { 'result' } }.to change(subject, :key).to('result')
        end
      end
    end

    describe 'with assignment syntax' do
      it 'assigns a value to the key as a string' do
        expect { subject.key = 1 }.to change(subject, :key).to(1)
      end
    end

    context 'when calling any method with arguments' do
      it 'calls the original method' do
        expect(subject.kind_of?(described_class)).to be true
      end

      it 'raises a NoMethodError when method doesn\'t exist' do
        expect { subject.foo('argument') }.to raise_error(NoMethodError)
      end

      context 'when a key with the same name exists' do
        let(:configuration) { {'kind_of?' => 'value'} }

        it 'calls the original method' do
          expect(subject.kind_of?(described_class)).to be true
        end
      end
    end

  end
end

