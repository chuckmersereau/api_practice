class ApplicationController < ActionController::API
  force_ssl(if: :ssl_configured?, except: :lb)
  MAX_PER_PAGE = 4_294_967_296

  before_action :redirect_to_mobile
  before_action :ensure_login, except: [:error_404, :error_500]
  before_action :ensure_setup_finished, except: [:error_404, :error_500]
  around_action :do_with_current_user, :set_user_time_zone, :set_locale

  def user_for_paper_trail
    impersonator_user || current_user
  end

  def close
    render layout: false
  end

  private

  def impersonator_user
    return nil unless session[:impersonator_id]
    @impersonator_user ||= User.find(session[:impersonator_id])
  end
  helper_method :impersonator_user

  def peek_enabled?
    user_signed_in? && current_user.developer == true
  end

  def ssl_configured?
    request.get? && !Rails.env.development? && !Rails.env.test?
  end

  def redirect_to_mobile
    session[:fullsite] = true if params[:fullsite] == 'true'
    session[:fullsite] = false if params[:fullsite] == 'false'

    return if session[:fullsite] || !mobile_agent
    url = 'http://m.mpdx.org/#' + request.fullpath[1..-1]
    redirect_to url
    false
  end

  def mobile_agent
    # rubocop:disable Metrics/LineLength, RegexpLiteral
    return unless request.user_agent
    /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.match(request.user_agent) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.match(request.user_agent[0..3])
  end

  def ensure_login
    return true if user_signed_in?

    if $request_test
      sign_in(:user, $user)
    else
      session[:user_return_to] = request.fullpath unless request.path == '/'
      if request.host =~ /us/
        redirect_to '/auth/relay'
      elsif request.host =~ /mpdxs|key/
        redirect_to '/auth/key'
      else
        flash[:timeout] = true
        redirect_to '/login'
      end
      return false
    end
    true
  end

  def ensure_setup_finished
    if user_signed_in? && (current_user.setup_mode? || !current_account_list) && !allowed_setup_request
      redirect_to setup_path(:org_accounts)
      false
    end
  end

  def allowed_setup_request
    return true if request.path == '/logout'
    params[:controller] == 'preferences' && params[:action] == 'update'
  end

  def set_user_time_zone
    old_time_zone = Time.zone
    if user_signed_in? && current_user.preferences[:time_zone]
      Time.zone = current_user.preferences[:time_zone]
    elsif cookies[:timezone]
      Time.zone = ActiveSupport::TimeZone[-cookies[:timezone].to_i.minutes]
      current_user.update_attribute(:time_zone, Time.zone.name) if user_signed_in?
    end
    yield
  ensure
    Time.zone = old_time_zone
  end

  def after_sign_out_path_for(_resource_or_scope = :user)
    case session[:signed_in_with]
    when 'relay'
      "https://signin.relaysso.org/cas/logout?service=#{login_url}"
    when 'key'
      "https://thekey.me/cas/logout?service=#{login_url}"
    else
      login_url
    end
  end

  def locale
    return 'en' unless user_signed_in?
    current_user.preferences[:locale] || 'en'
  end

  helper_method :locale

  def current_account_list
    return @current_account_list if @current_account_list

    @current_account_list = current_user.account_lists.where(id: session[:current_account_list_id]).first if session[:current_account_list_id].present?
    @current_account_list ||= default_account_list
    return unless @current_account_list
    session[:current_account_list_id] = @current_account_list.id
    @current_account_list
  end
  helper_method :current_account_list

  def default_account_list
    unless @default_account_list
      if current_user.default_account_list.present?
        @default_account_list = current_user.account_lists.find_by(id: current_user.default_account_list) ||
                                current_user.account_lists.first
      else
        @default_account_list = current_user.account_lists.first
        return unless @default_account_list
        current_user.default_account_list = @default_account_list.id
        current_user.save
      end
    end

    @default_account_list
  end

  def do_with_current_user
    Thread.current[:user] = current_user
    begin
      yield
    ensure
      Thread.current[:user] = nil
    end
  end

  def set_locale
    old_locale = FastGettext.locale || 'en'
    update_gettext_and_i18n(locale)
    yield
    update_gettext_and_i18n(old_locale)
  end

  def update_gettext_and_i18n(setted_locale)
    FastGettext.locale = setted_locale
    I18n.locale = setted_locale.delete('-')
  end

  def render_csv(filename = nil)
    filename ||= params[:controller]
    filename += '.csv'

    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers['Content-type'] = 'text/plain'
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = '0'
    else
      headers['Content-Type'] ||= 'text/csv'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    end

    render layout: false
  end

  def filters_params
    @filters_params ||= params[:filters] || {}
  end
  helper_method :filters_params

  def tag_params
    filters_params[:tags]
  end
  helper_method :tag_params

  def authenticate_admin_user!
    return if admin_user_signed_in?

    session[:user_return_to] = request.fullpath
    redirect_to '/auth/admin'
    false
  end

  def auth_hash
    request.env['omniauth.auth']
  end

  def per_page
    @per_page = params[:per_page] || params[:limit]
    @per_page = if @per_page == 'All'
                  MAX_PER_PAGE
                else
                  @per_page.to_i > 0 ? @per_page : 25
                end

    @per_page.to_i if @per_page
  end

  def page
    if params[:per_page] == 'All'
      1
    else
      page_int = ((params[:offset].to_f + 1) / per_page).ceil if params[:offset]
      page_int ||= params[:page].to_i if params[:page]
      page_int.to_i > 0 ? page_int : 1
    end
  end

  def correct_from(collection)
    if page > total_pages(collection)
      0
    else
      from = collection.offset + 1
      from > collection.total_entries ? 0 : from
    end
  end

  def total_pages(collection)
    @total_pages ||= (collection.total_entries / per_page.to_f).ceil
  end

  def correct_to(collection)
    if page > total_pages(collection)
      0
    else
      to = collection.offset + collection.length
      to > collection.total_entries ? 0 : to
    end
  end
end
