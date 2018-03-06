#spec/aim_provider_spec.rb

require 'spec_helper'

describe 'aim::provider' do

  #let(:facts) {{ :is_virtual => 'false' }}
  #let(:title) { 'aim::provider' }
  #let(:node) {'puppet01.cyberark.local'}

  let(:facts) do {
    :installed_carkaim => 'package CARKaim is not installed'}
  end

  it { is_expected.to compile }
  it { is_expected.to compile.with_all_deps }

  #it { should include_class('aim::package') }
  #it { should include_class('aim::environment') }
  #it { should include_class('aim::service') }

end
