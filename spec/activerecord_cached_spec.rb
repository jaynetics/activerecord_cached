# frozen_string_literal: true

RSpec.describe ActiveRecordCached do
  let!(:record) { Pizza.create!(name: 'Funghi') }

  describe 'CRUDCallbacks' do
    it 'clears cached values after create' do
      expect { Pizza.create!(name: 'Spinaci') }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to(['Funghi', 'Spinaci'])
    end

    it 'clears cached values after destroy' do
      expect { record.destroy! }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to([])
    end

    it 'clears cached values after update' do
      expect { record.update!(name: 'Speciale') }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to(['Speciale'])
    end

    it 'is installed only once' do
      5.times { Pizza.cached_pluck(:name) }
      expect(Pizza).to receive(:clear_cached_values).once
      record.destroy!
    end
  end

  describe 'MassOperationWrapper' do
    it 'clears cached values after delete_all' do
      expect { Pizza.delete_all }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to([])
    end

    it 'clears cached values after delete_all on relations' do
      expect { Pizza.where(id: record.id).delete_all }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to([])
    end

    it 'clears cached values after insert_all' do
      expect { Pizza.insert_all([name: 'Spinaci']) }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to(['Funghi', 'Spinaci'])
    end

    it 'clears cached values after update_all' do
      expect { Pizza.update_all(name: 'Speciale') }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to(['Speciale'])
    end

    it 'clears cached values after update_all on relations' do
      expect { Pizza.where(id: record.id).update_all(name: 'Speciale') }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to(['Speciale'])
    end
  end

  describe '::clear_cached_values' do
    it 'clears cached values for the given model' do
      Curry.create!(name: 'Matsaman')
      Pizza.cached_pluck(:name)
      Curry.cached_pluck(:name)
      clear_tables # direct sql operation not detected by callbacks
      expect { Pizza.clear_cached_values }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to([])

      # other model should not be affected
      expect(ActiveRecordCached).not_to receive(:load)
      expect(Curry.cached_pluck(:name)).to eq(['Matsaman'])
    end

    it 'clears the values for the whole model when called on a relation' do
      Pizza.cached_pluck(:name)
      clear_tables # direct sql operation not detected by callbacks
      expect { Pizza.limit(0).clear_cached_values }
        .to change { Pizza.cached_pluck(:name) }.from(['Funghi']).to([])
    end
  end

  describe '::cached_pluck' do
    it 'behaves like ::pluck' do
      expect(Pizza.cached_pluck(:name)).to eq(['Funghi'])
      expect(Pizza.cached_pluck(:name, :id)).to eq([['Funghi', record.id]])
    end

    it 'is cached' do
      expect(ActiveRecordCached).to receive(:query_db).once.and_call_original
      expect(Pizza.cached_pluck(:name)).to eq(['Funghi'])
      expect(Pizza.cached_pluck(:name)).to eq(['Funghi'])
    end

    it 'is cached on relations' do
      expect(ActiveRecordCached).to receive(:query_db).once.and_call_original
      expect(Pizza.limit(0).cached_pluck(:name)).to eq([])
      expect(Pizza.limit(0).cached_pluck(:name)).to eq([])
    end
  end

  describe '::cached_records' do
    it 'behaves like ::records' do
      expect(Pizza.select(:name).cached_records.first.attributes)
        .to eq('name' => 'Funghi', 'id' => nil)
      expect(Pizza.select(:name, :id).cached_records.first.attributes)
        .to eq('name' => 'Funghi', 'id' => record.id)
    end

    it 'is cached' do
      expect(ActiveRecordCached).to receive(:query_db).once.and_call_original
      expect(Pizza.cached_records).to eq [record]
      expect(Pizza.cached_records).to eq [record]
    end

    it 'is cached on relations' do
      expect(ActiveRecordCached).to receive(:query_db).once.and_call_original
      expect(Pizza.select(:name).cached_records.map(&:attributes))
        .to eq(['name' => 'Funghi', 'id' => nil])
      expect(Pizza.select(:name).cached_records.map(&:attributes))
        .to eq(['name' => 'Funghi', 'id' => nil])
    end
  end

  describe '::cached_count' do
    it 'behaves like ::count' do
      expect(Pizza.cached_count).to eq 1
      expect(Pizza.where(name: 'Diavolo').cached_count).to eq 0
    end

    it 'is cached' do
      expect(ActiveRecordCached).to receive(:query_db).once.and_call_original
      expect(Pizza.cached_count).to eq 1
      expect(Pizza.cached_count).to eq 1
    end

    it 'is cached on relations' do
      expect(ActiveRecordCached).to receive(:query_db).once.and_call_original
      expect(Pizza.where(name: 'Diavolo').cached_count).to eq 0
      expect(Pizza.where(name: 'Diavolo').cached_count).to eq 0
    end
  end

  describe 'limits' do
    it 'warns if max_count is reached' do
      old_max = ActiveRecordCached.max_count
      ActiveRecordCached.max_count = 1
      second_pizza = Pizza.create!(name: 'Spinaci')
      expect { Pizza.cached_pluck(:name) }.to output(/>= 1 max_count/).to_stderr
    ensure
      ActiveRecordCached.max_count = old_max
    end

    it 'warns if max_bytes is reached' do
      old_max = ActiveRecordCached.max_bytes
      ActiveRecordCached.max_bytes = 1
      expect { Pizza.cached_pluck(:name) }.to output(/>= 1 max_bytes/).to_stderr
    ensure
      ActiveRecordCached.max_bytes = old_max
    end

    it 'calls the custom handler' do
      old_handler = ActiveRecordCached.on_limit_reached
      arr = []
      ActiveRecordCached.on_limit_reached = ->(msg) { arr << msg }
      expect(ActiveRecordCached).to receive(:max_bytes_exceeded?).and_return(true)
      expect { Pizza.cached_pluck(:name) }.to change(arr, :size).by(1)
    ensure
      ActiveRecordCached.on_limit_reached = old_handler
    end
  end
end
