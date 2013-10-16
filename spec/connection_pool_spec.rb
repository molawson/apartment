require 'spec_helper'

class SomeClass < ActiveRecord::Base
end

describe Apartment::ConnectionPool do

  let(:config) { Apartment::Test.config['connections']['postgresql'] }
  let(:database) { Apartment::Test.next_db }
  let(:spec) do
    config.clone.tap do |c|
      c[:database] = database
    end
  end

  before(:each) do
    Apartment::Database.stub(:config).and_return(config)
  end

  subject { Apartment::ConnectionPool.new }

  describe '#use' do
    it 'returns a connection' do
      expect(subject.use(spec)).to(
        be_an(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      )
    end

    context 'first time using the given pool' do
      context 'connection is not succesful' do
        before(:each) { spec.merge!({ 'database' => 'unknown_database' }) }

        it 'raises an error' do
          expect {
            subject.use(spec)
          }.to raise_error
        end
      end

      context 'connection is successful' do
        let(:connection_pool) { double('connection_pool', connection: double) }
        it 'creates a connection' do
          ActiveRecord::Base.should_receive(:establish_connection).
            and_return(connection_pool)
          subject.use(spec)
        end

        it 'adds the connection pool to the connection handler' do
          expect {
            subject.use(spec)
          }.to change{
            ActiveRecord::Base.connection_handler.connection_pools.size
          }.by(1)
        end
      end
    end

    context 'second time using the given pool' do
      before(:each) { subject.use(spec) }

      it 'should not create a connection' do
        ActiveRecord::Base.should_not_receive(:establish_connection)
        subject.use(spec)
      end
    end
  end

  describe '#class_for_model' do
    context 'model is ActiveRecord::Base' do
      let(:klass) { ActiveRecord::Base }

      it 'returns the model' do
        expect(subject.class_for_model(klass)).to eq(klass)
      end
    end

    context 'model is not ActiveRecord::Base' do
      let(:klass) { SomeClass }

      context 'using schemas' do
        before(:each) do
          Apartment.configure { |c| c.use_schemas = true }
        end

        it 'returns the model' do
          expect(subject.class_for_model(klass)).to eq(klass)
        end
      end

      context 'not using schemas' do
        before(:each) do
          Apartment.configure { |c| c.use_schemas = false }
        end

        context 'model is in the excluded_models list' do
          before(:each) do
            Apartment.configure { |c| c.excluded_models = ['SomeClass'] }
          end

          it 'returns the model' do
            expect(subject.class_for_model(klass)).to eq(klass)
          end
        end

        context 'model is not in the excluded_models list' do
          before(:each) do
            Apartment.configure { |c| c.excluded_models = [] }
            Apartment::Database.stub(:current_database).and_return('dummy_database')
          end

          it 'returns the dummy model for the current database' do
            expect(subject.class_for_model(klass)).to eq(Apartment::DummyDatabase)
          end
      end
      end
    end
  end
end
