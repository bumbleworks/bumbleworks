module MakeSomeHoneyTask
  def before_update(params)
    fields['what_happened'] = params['happening']
  end
end
