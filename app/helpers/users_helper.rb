module UsersHelper

  def locale_form_column(record, input_name)
    options = [[ I18n.t('locale.czech'), 'cs'],
               [ I18n.t('locale.english'), 'en']]
    select(:record, :locale, options)
  end

end
