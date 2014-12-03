require 'spec_helper'

describe MemberBalanceService do
  MEMBER_ID = 750
  subject { MemberBalanceService.new(MEMBER_ID) }
  it { expect(subject).to respond_to(:pledged_collateral) }
  it { expect(subject).to respond_to(:total_securities) }
  it { expect(subject).to respond_to(:effective_borrowing_capacity) }
  describe "`pledged_collateral` method" do
    let(:pledged_collateral) {subject.pledged_collateral}
    it "should return a hash of hashes containing pledged collateral values" do
      expect(pledged_collateral.length).to be >= 1
      expect(pledged_collateral[:mortgages]).to be_kind_of(Hash)
      expect(pledged_collateral[:mortgages][:absolute]).to be_kind_of(Numeric)
      expect(pledged_collateral[:mortgages][:percentage]).to be_kind_of(Float)
      expect(pledged_collateral[:agency]).to be_kind_of(Hash)
      expect(pledged_collateral[:agency][:absolute]).to be_kind_of(Numeric)
      expect(pledged_collateral[:agency][:percentage]).to be_kind_of(Float)
      expect(pledged_collateral[:aaa]).to be_kind_of(Hash)
      expect(pledged_collateral[:aaa][:absolute]).to be_kind_of(Numeric)
      expect(pledged_collateral[:aaa][:percentage]).to be_kind_of(Float)
      expect(pledged_collateral[:aa]).to be_kind_of(Hash)
      expect(pledged_collateral[:aa][:absolute]).to be_kind_of(Numeric)
      expect(pledged_collateral[:aa][:percentage]).to be_kind_of(Float)
    end
    describe "`total_securities` method" do
      let(:total_securities) {subject.total_securities}
      it "should return a hash of hashes containing total security values" do
        expect(total_securities.length).to be >= 1
        expect(total_securities[:pledged_securities]).to be_kind_of(Hash)
        expect(total_securities[:pledged_securities][:absolute]).to be_kind_of(Integer)
        expect(total_securities[:pledged_securities][:percentage]).to be_kind_of(Float)
        expect(total_securities[:safekept_securities]).to be_kind_of(Hash)
        expect(total_securities[:safekept_securities][:absolute]).to be_kind_of(Integer)
        expect(total_securities[:safekept_securities][:percentage]).to be_kind_of(Float)
      end
    end
    describe "`effective_borrowing_capacity` method" do
      let(:effective_borrowing_capacity) {subject.effective_borrowing_capacity}
      it "should return a hash of hashes containing effective borrowing capacity values" do
        expect(effective_borrowing_capacity.length).to be >= 1
        expect(effective_borrowing_capacity[:used_capacity]).to be_kind_of(Hash)
        expect(effective_borrowing_capacity[:used_capacity][:absolute]).to be_kind_of(Integer)
        expect(effective_borrowing_capacity[:used_capacity][:percentage]).to be_kind_of(Float)
        expect(effective_borrowing_capacity[:unused_capacity]).to be_kind_of(Hash)
        expect(effective_borrowing_capacity[:unused_capacity][:absolute]).to be_kind_of(Integer)
        expect(effective_borrowing_capacity[:unused_capacity][:percentage]).to be_kind_of(Float)
      end
    end
  end
end