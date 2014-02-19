require 'ruote/exp/flow_expression'
require 'bumbleworks/support/flow_expression'

module Ruote::Exp
  class BroadcastEventExpression < FlowExpression
    include Bumbleworks::Support::FlowExpression

    names :broadcast_event

    def consider_tag
      update_tree
      h.updated_tree[1]['tag'] = tag_from_attribute
      super
    end

    def apply
      reply_to_parent(h.applied_workitem)
    end
  end
end
