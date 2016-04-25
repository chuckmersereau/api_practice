class DonationReports::DonationInfoArraySerializer < ActiveModel::ArraySerializer
  def each_serializer
    DonationReports::DonationInfoSerializer
  end
end
