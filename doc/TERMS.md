Process Definitions - a map of the assembly line, which dictates where the activities, gateways, events, etc. will be encountered by the product.
Process Instances - a trip through the assembly line, taken by a single product
Activities - actions performed by factory workers or robots on the product - carving, painting, cleaning, filling, soldering, etc.
Gateways - decision points on where the product should go, when the assembly line branches (e.g. larger widgets go to the Big Widget Cleaning Station, smaller ones go to the Small Widget Cleaning Station)
Message Events, Schedules - pausing the line for a shift change or lunch break, waiting at a certain stage until a needed part has been delivered, etc.
Workitem/Payload - the Product
Worker - turning on the power to the Conveyor Belt
Workflow Engine - the Factory
  This is an abstract term that encompasses all of the above.  It's a term that's often used in comparison with a "state machine."
