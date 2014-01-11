module MakeSomeHoneyTask
  def before_update(params)
    fields['what_happened'] = params['happening']
  end

  def after_dispatch
    fields['i_was_dispatched'] = 'yes_i_was'
    update
  end
end
