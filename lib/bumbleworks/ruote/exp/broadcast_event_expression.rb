require 'ruote/exp/flow_expression'

module Ruote::Exp
  class BroadcastEventExpression < FlowExpression
    names :broadcast_event

    def consider_tag
      update_tree
      h.updated_tree[1]['tag'] = attribute_text.to_s
      super
    end

    def apply
      reply_to_parent(h.applied_workitem)
    end
  end
end
