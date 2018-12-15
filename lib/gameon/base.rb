module GameOn

  module Middleware 
    include Mushin::Domain::Middleware
  end

  module DSL 
    include Mushin::DSL

    def self.find current_context_title, current_activity_title

      Mushin::DSL.contexts.each do |context|
	if context.title == current_context_title
	  context.activities.each do |activity|
	    if activity.title == current_activity_title
	      @middlewares = []
	      activity.uses.each do |middleware|

		if @middlewares.empty?
		  p "adding first middleware !!!"
		  @middlewares << middleware 
		  p @middlewares
		else
		  @middlewares.each do |prev|
		    if prev.name == middleware.name && prev.opts == middleware.opts && prev.params ==  middleware.params
		      p "this activation already exists, nothing to do!!!"
		    else
		      p "adding new activation"
		      @middlewares << middleware 
		      p @middlewares
		    end
		  end
		end

	      end
	      return @middlewares
	    end
	  end
	end

      end
      Dir["./gameon/*"].each {|file| load file } 
    end
  end

  module Engine
    extend Mushin::Engine
    class << self
      def run id, domain_context, activity
	stack = Mushin::Middleware::Builder.new do
	  (GameOn::DSL.find domain_context, activity).uniq.each do |middleware|
	    p "GameOn Logging: use #{middleware.name}, #{middleware.opts}, #{middleware.params}"
	    use middleware.name, middleware.opts, middleware.params
	  end
	end
	stack.insert_before 0, Object.const_get('GameOn::Persistence::DS'), {}, {:id => id}
	#@setup_middlewares.each do |setup_middleware|
	#  stack.insert_before 0, setup_middleware 
	#end
	stack.call
      end
    end
  end
=begin
  class Env 
    extend Mushin::Env

    class << self
      attr_accessor :id

      def get id
	GameOn::Persistence::DS.load id.to_s + 'gameon' #TODO some app key based encryption method 
      end

      def set id, &block 
	@id = id.to_s + 'gameon' 
	def context current_context_title, &block
	  @current_context_title = current_context_title  
	  @activities = []  
	  def activity current_activity_title 
	    @activities << current_activity_title 
	  end
	  instance_eval(&block)
	end
	instance_eval(&block)

	GameOn::Engine.setup [Object.const_get('GameOn::Persistence::DS')]
	@activities.uniq.each do |current_activity_title| 
	  GameOn::Engine.run @current_context_title, current_activity_title  
	end
	@activities = [] # reset the activities 
	return GameOn::Persistence::DS.load @id 
      end
    end
  end
=end
#=begin
  class Env
    extend Mushin::Env

    attr_accessor :id
    #def initialize id
    #  @id = id
    #end

    def set id, &block
      @id = id.to_s + 'gameon' 
      def context current_context_title, &block
	@current_context_title = current_context_title  
	@activities = []  
	def activity current_activity_title 
	  @activities << current_activity_title 
	end
	instance_eval(&block)
      end
      instance_eval(&block)

      #GameOn::Env.id = @id
      #GameOn::Engine.setup [[Object.const_get('GameOn::Persistence::DS'), {}, {:id => @id}]]
      # [[Object.const_get('GameOn::Persistence::DS'), {}, {:id => @id}]].each do |e|
      #	 p "#{e[0]}, #{e[1]}, #{e[2]}"
      #       end
      #GameOn::Engine.setup "#{Object.const_get('GameOn::Persistence::DS')}, #{{}}, #{{:id => @id}}"

      @activities.uniq.each do |current_activity_title| 
	GameOn::Engine.run @id, @current_context_title, current_activity_title  
      end
      #@activities = [] # reset the activities 
      return GameOn::Persistence::DS.load @id 
    end

    def get id
      GameOn::Persistence::DS.load id.to_s + 'gameon' #TODO some app key based encryption method                                          
    end

    class << self 
      def set id, &block
	e = Env.new
	e.set id, &block 
      end

      def get id
	e = Env.new
	e.get id
      end
      def all
	#TODO returns all the gameon enviroments in the DS
      end
    end
  end
  #=end
  
end
