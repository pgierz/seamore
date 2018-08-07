require "json"

def variables_from_datarequest(datarequest_path)
  j = JSON.parse File.read(datarequest_path)
  j["variable_entry"].keys
end