class PlanCategoriesController < ApplicationController
  include YearlyController

  # Callbacks, in order
  load_resource
  add_filter_to_set_resource_year
  authorize_resource
  add_filter_restricting_resources_to_year_in_route
  before_filter :events_for_select, :only => [:create, :edit, :new, :update]
  before_filter :expose_plans, :only => [:show, :update]

  def index
    categories = @plan_categories \
      .select("plan_categories.*, events.name as event_name") \
      .yr(@year).joins(:event).order("events.name, plan_categories.name")
    @plan_categories_by_event = categories.group_by {|c| c.event_name}
  end

  def show
    @show_availability = Plan.inventoried_plan_in? @plans
  end

  def create
    if @plan_category.save
      redirect_to(@plan_category, :notice => 'Plan category created.')
    else
      render :action => "new"
    end
  end

  def update
    if params[:commit] == 'Update Order'
      @plan_category.reorder_plans(params[:plan_order])
    else
      unless @plan_category.update_attributes(params[:plan_category])
        render :action => "edit" and return
      end
    end

    # We were successful, regardless of what we did :-)
    redirect_to(@plan_category, :notice => 'Plan category updated.')
  end

  def destroy
    begin
      @plan_category.destroy
    rescue ActiveRecord::DeleteRestrictionError
      flash[:alert] = "Cannot delete the '#{@plan_category.name}' category
        because its plans have already been selected by attendees"
    end
    redirect_to plan_categories_url
  end

  private

  def events_for_select
    @events_for_select = Event.yr(@year).alphabetical.all.map {|e| [e.name, e.id]}
  end

  def expose_plans
    visible_plans = @plan_category.plans.accessible_by(current_ability, :show)
    @plans = visible_plans.order('cat_order')
    @show_order_fields = can?(:update, Plan) && @plans.count > 1
  end

end
