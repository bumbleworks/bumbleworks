require 'ruote/exp/flow_expression'
require 'ruote/exp/fe_await'

module Ruote::Exp
  class WaitForEventExpression < AwaitExpression
    names :wait_for_event

    # This does the same as the base AwaitExpression#apply, except that this
    # will always be a global listener, listening for a 'left_tag' event, and
    # the event's workitem will be discarded after the reply is complete.  The
    # event's workitem is only used for comparisons in the where clause (see
    # #reply).
    def apply
      update_tree
      h.updated_tree[1]['global'] = true
      h.updated_tree[1]['left_tag'] = attribute_text.to_s
      h.updated_tree[1]['merge'] = 'drop'
      super
    end

    # On apply, the workitem for this FlowExpression was replaced by the workitem
    # from the event.  So when we refer to "f:" in this #reply method, we're
    # looking at the event's workitem, which will be discarded at the end of this
    # reply (and replaced with the applied workitem).  In order to compare the
    # event's workitem with the applied workitem (so we can determine whether or
    # not the event was intended for us), we assign the applied_workitem's fields
    # to a hash on the event's workitem fields, available at "f:receiver.*".
    def reply(workitem)
      update_tree
      # If we have a where clause at all...
      if translated_where = attribute(:where, nil, :escape => true)
        if translated_where.to_s == 'entities_match'
          # Check to see that the event's entity is equal to the current workitem's
          # entity.  If so, this message is intended for us.
          translated_where = '${f:entity_id} == ${f:receiver.entity_id} && ${f:entity_type} == ${f:receiver.entity_type}'
        else
          # This just gives us a shortcut so the process definition reads more
          # clearly.  You could always use "${f:" and "${f:receiver." in your
          # where clauses, but you have to remember that the former refers to the
          # incoming event's workitem, and the latter is the workitem of the
          # listening process.
          translated_where.gsub!('${event:', '${f:') # event workitem
          translated_where.gsub!('${this:', '${f:receiver.') # listening workitem
        end
        h.updated_tree[1]['where'] = translated_where
      end
      workitem['fields']['receiver'] = h.applied_workitem['fields']
      super
    end
  end
end