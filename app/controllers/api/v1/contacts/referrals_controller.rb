class Api::V1::Contacts::ReferralsController < Api::V1::BaseController
  def index
    contact = Contact.find(params[:id] || params[:contact_id])
    return render json: contact.contact_referrals_by_me,
                  each_serializer: ReferralsSerializer if contact
    render nothing: true, status: 404
  end
end
