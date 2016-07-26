require 'spec_helper'

describe Gestalt::Store do
  let(:configuration) { {'key' => 'value'} }

  subject { described_class.new('test', configuration) }

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
    let(:parent) { described_class.new('parent', configuration) }

    subject { described_class.new('child', configuration['child'], parent) }

    it 'returns the breadrcumbs in the expected format' do
      expect(subject.breadcrumbs).to eq('"parent" -> "child"')
    end

    context 'when subject is root' do
      subject { parent }

      it 'returns the key name' do
        expect(subject.breadcrumbs).to eq('"parent"')
      end
    end

    context 'when key name is an object' do
      let(:object) { Object.new }
      let(:configuration) { {object => {'key' => 'value'}} }

      subject { described_class.new(object, configuration[object], parent) }

      it 'returns breadcrumbs with the string representation of the object' do
        expect(subject.breadcrumbs).to eq("\"parent\" -> #{object.to_s}")
      end
    end

  end

  describe 'method chain syntax' do
    context 'when keys are strings' do
      let(:configuration) { {'key_1' => {'key_2' => {'key_3' => 'value'}}} }
      
      it 'allows navigation through method chaining' do
        expect(subject.key_1.key_2.key_3).to be(configuration['key_1']['key_2']['key_3'])
      end

      it 'allows interchangeable access' do
        expect(subject.key_1['key_2'].key_3).to be(configuration['key_1']['key_2']['key_3'])
      end
    end

    context 'when keys are symbols' do
      let(:configuration) { {'key_1' => {key_2: {key_3: 'value'}}} }

      it 'raises an error' do
        expect {
          subject.key_1.key_2.key_3
        }.to raise_error(Gestalt::KeyNotFoundError, 'Key "key_2" is not present at "test" -> "key_1"')
      end
    end

    describe 'hash methods' do
      context 'when hash method is called' do
        it 'routes the call to the configuration hash' do
          expect(configuration).to receive(:has_key?).with('key')
          subject.has_key?('key')
        end
      end
    end
    
    describe 'key assignment' do
      it 'assigns a value to the key as a string' do
        expect { subject.key = 1 }.to change(subject, :key).to(1)
      end

      it 'sets the value into the specified key' do
        subject.key = 1
        expect(subject.key).to eq(1) 
      end
    end

    context 'when calling a method named the same as a key' do
      let(:configuration) { {'dup' => 'value'} }

      it 'calls the original method' do
        expect(subject.dup).to_not be(subject)
      end
    end

    context 'when calling any method with a block' do
      it 'calls the original method' do
        expect(subject.tap { |o| o.inspect }).to be(subject)
      end

      it 'raises a NoMethodError when method doesn\'t exist' do
        expect { subject.foo { |o| o.inspect } }.to raise_error(NoMethodError)
      end

      context 'when a key with the same name exists' do
        let(:configuration) { {'tap' => 'value'} }

        it 'calls the original method' do
          expect(subject.tap { |o| o.inspect }).to be(subject)
        end
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

