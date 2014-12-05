module Sipity
  # Runners are a means of encapsulating an action's logic.
  #
  # The current construction of Rails controller's discourages re-using an
  # action method for other interfaces (i.e. command-line utilities).
  #
  # By introducing the Runner concept I am hopefully alleviating much of the
  # pain of testing controllers. A controller can instead focus on mapping an
  # HTTP request to the correct Runner and handling the runner's response by
  # passing that information on to the HTTP requester.
  #
  # A runner also allows for an added boon: eliminating the over-abundance of
  # :before_filter methods used in a controller, and the confusing :except and
  # :only conditional before filters.
  #
  # If you want the filter concept to run do it as part of the runner. That way
  # you can make sure your command-line application adhears to the same policy.
  #
  # @see [Jim Weirich's Wyriki](https://github.com/jimweirich/wyriki)
  module Runners
  end
end
