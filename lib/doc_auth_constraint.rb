class DocAuthConstraint
  def self.matches?(request)
    request.session[:doc_user] == 'superduper'
  end
end
