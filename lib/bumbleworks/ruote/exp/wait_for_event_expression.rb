require 'ruote/exp/flow_expression'
require 'ruote/exp/fe_await'

module Ruote::Exp
  class WaitForEventExpression < AwaitExpression
    names :wait_for_event

    def apply
      update_tree
      h.updated_tree[1]['global'] = true
      h.updated_tree[1]['left_tag'] = attribute_text.to_s
      h.updated_tree[1]['merge'] = 'drop'
      super
    end

    def reply(workitem)
      update_tree
      if translated_where = attribute(:where, nil, :escape => true)
        if translated_where.to_s == 'entities_match'
          translated_where = '${f:entity_id} == ${f:receiver.entity_id} && ${f:entity_type} == ${f:receiver.entity_type}'
        else
          translated_where.gsub!('${event:', '${f:')
          translated_where.gsub!('${this:', '${f:receiver.')
        end
        h.updated_tree[1]['where'] = translated_where
      end
      workitem['fields']['receiver'] = h.applied_workitem['fields']
      super
    end
  end
end