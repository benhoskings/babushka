include Prompt::Helpers

def read_from_prompt prompt = '? '
  (@values.shift || '').to_s
end
