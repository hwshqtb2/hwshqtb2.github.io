module Jekyll
  # Small shared helpers for the plugins in this template.
  module PluginUtils
    module_function

    # Normalise a front matter list (categories / tags) into an array of
    # non-empty, unique strings.
    #
    #   nil               -> []
    #   "a b"             -> ["a", "b"]          (Jekyll's space separated form)
    #   ["a", ["b"]]      -> ["a", "b"]
    #   ["a", " ", "a"]   -> ["a"]
    def normalize_list(value)
      return [] if value.nil?

      values = value.is_a?(String) ? value.split(%r!\s+!) : Array(value)
      values.flatten
            .map { |item| item.to_s.strip }
            .reject(&:empty?)
            .uniq
    end

    # Normalise an `order` value into integer segments:
    # 2 -> [2], "2.2.1" -> [2, 2, 1], 2.0 -> [2]. Returns nil when unset.
    def order_segments(value)
      return nil if value.nil? || value.to_s.strip.empty?

      number = value.is_a?(Float) && value == value.to_i ? value.to_i : value
      number.to_s.split(".").map(&:to_i)
    end
  end
end
