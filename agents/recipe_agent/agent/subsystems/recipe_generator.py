# File: MY_RECIPE_AGENT/recipe_agent/subsystems/recipe_generator.py
from google.adk.agents import LlmAgent, SequentialAgent
from .. import tools

# These are now internal implementation details of the subsystem
_database_agent = LlmAgent(
    name="InternalDatabaseAgent", model="gemini-2.0-flash",
    instruction="Your only job is to use 'fetch_groceries_from_firebase'. The user ID is 'r6JTIa1WulR9J42HqjgouCe1fRA3'. Interpret timeframes and pass the correct number of days.",
    tools=[tools.fetch_groceries_from_firebase],
    output_key="fetched_groceries"
)

_recipe_generator_agent = LlmAgent(
    name="InternalRecipeGeneratorAgent", model="gemini-2.0-flash",
    instruction="You are a creative chef AI. Given ingredients from state key 'fetched_groceries', invent one recipe. 1. List all required ingredients. 2. Call `check_ingredient_availability`. 3. Present the recipe, full ingredient list, missing items, and cooking instructions.",
    tools=[tools.check_ingredient_availability],
    output_key="recipe_suggestion"
)

# The sequential workflow remains the same
_recipe_workflow = SequentialAgent(
    name="RecipeWorkflow",
    sub_agents=[_database_agent, _recipe_generator_agent]
)

# This is the new, EXPORTED agent that will be used as a tool.
# Its purpose is to run the workflow and provide the final answer.
RecipeGeneratorToolAgent = LlmAgent(
    name="RecipeGeneratorTool",
    model="gemini-2.0-flash",
    description="Use this tool to find a recipe based on a user's purchase history and constraints like allergies, time, or skill level.",
    instruction="You are the manager of the recipe generation workflow. Your only job is to execute the 'RecipeWorkflow' sub-agent to fulfill the user's request. After the workflow is complete, provide its final output as your own.",
    sub_agents=[_recipe_workflow]
)