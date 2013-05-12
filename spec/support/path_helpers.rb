def spec_path
  File.expand_path('..', File.dirname(__FILE__))
end

def fixtures_path
  File.join(spec_path, 'fixtures')
end