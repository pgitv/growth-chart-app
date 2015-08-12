require 'igneous/smart/launch_context'

describe Igneous::Smart::LaunchContext do
  let(:launch_context) { Igneous::Smart::LaunchContext }

  describe '#context' do
    it 'creates launch context hash' do
      params = {
        'PAT_PersonId'   => '1',
        'PAT_PPRCode'    => '2',
        'VIS_EncntrId'   => '3',
        'USR_PersonId'   => '4',
        'USR_PositionCd' => '5',
        'DEV_Location'   => '6',
        'APP_AppName'    => '7'
      }

      allow(SecureRandom).to receive(:uuid).and_return '46134c2c-7412-4d53-b09e-e8ced4c73dbc'

      context = launch_context.context(params)
      retrieved_context = launch_context.find_by context_id: context.context_id

      expect(retrieved_context.context_id).to eq '46134c2c-7412-4d53-b09e-e8ced4c73dbc'
      expect(JSON.parse(retrieved_context.data)).to include('patient' => '1', 'ppr' => '2', 'encounter' => '3',
                                                            'user' => '4', 'position' => '5', 'device_location' => '6',
                                                            'app_name' => '7')
    end

    it 'constructs an empty SMART context when no params are present' do
      context = launch_context.context({})
      retrieved_context = launch_context.find_by context_id: context.context_id
      expect(JSON.parse(retrieved_context.data)).to be_empty
    end

    it 'constructs a complete SMART context when all params are present' do
      params = {
        'PAT_PersonId'   => '1',
        'PAT_PPRCode'    => '2',
        'VIS_EncntrId'   => '3',
        'USR_PersonId'   => '4',
        'USR_PositionCd' => '5',
        'DEV_Location'   => '6',
        'APP_AppName'    => '7'
      }

      context = launch_context.context(params)
      retrieved_context = launch_context.find_by context_id: context.context_id
      expect(JSON.parse(retrieved_context.data)).to include('patient' => '1', 'ppr' => '2', 'encounter' => '3',
                                                            'user' => '4', 'position' => '5', 'device_location' => '6',
                                                            'app_name' => '7')
    end

    it 'strips .00 added by PowerChart from all numeric parameter values' do
      params = {
        'PAT_PersonId' => '1.00',
        'VIS_EncntrId' => '2.00',
        'DEV_Location' => 'East Wing',
        'APP_AppName'  => 'Spec Test'
      }

      context = launch_context.context(params)
      retrieved_context = launch_context.find_by context_id: context.context_id
      expect(JSON.parse(retrieved_context.data)).to include('patient' => '1', 'encounter' => '2',
                                                            'device_location' => 'East Wing',
                                                            'app_name' => 'Spec Test')
    end

    it 'will not add key, value pair when value is not supplied or nil' do
      params = {
        'PAT_PersonId' => '1.00',
        'VIS_EncntrId' => '2.00',
        'PAT_PPRCode' => nil,
        'DEV_Location' => nil,
        'APP_AppName'  => nil
      }

      context = launch_context.context(params)
      retrieved_context = launch_context.find_by context_id: context.context_id
      expect(JSON.parse(retrieved_context.data)).to include('patient' => '1', 'encounter' => '2')
      expect(JSON.parse(retrieved_context.data)).to_not include('ppr' => '0', 'device_location' => nil,
                                                                'app_name' => nil)
    end
  end
end
