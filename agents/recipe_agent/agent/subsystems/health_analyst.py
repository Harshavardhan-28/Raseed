# File: MY_RECIPE_AGENT/recipe_agent/subsystems/health_analyst.py
from google.adk.agents import LlmAgent, SequentialAgent, ParallelAgent
from google.adk.tools import google_search
from agent import tools

# --- THE USER'S INNOVATIVE IDEA: PARALLEL SEARCH ---

# A specialist agent that ONLY searches the database.
DatabaseSearchAgent = LlmAgent(
    name="DatabaseSearchAgent", model="gemini-2.0-flash",
    instruction="Your only job is to use 'fetch_groceries_from_firebase' for user 'ZFW7wDV8Exap8FLXGLH5C0TL9NH3'. If the user's query mentions a timeframe, use it. Otherwise, use a default of 30 days.",
    tools=[tools.fetch_groceries_from_firebase],
    output_key="database_groceries" # Save result to a unique key
)

# A specialist agent that ONLY searches Google for the specific item.
GoogleSearchAgent = LlmAgent(
    name="GoogleSearchAgent", model="gemini-2.5-pro",
    instruction="You are a web researcher. The user's original query is in the state key 'last_user_message'. Your only job is to extract the specific food item from that query and use `google_search` to find its nutritional information and average price. Be very concise in your search.",
    tools=[google_search],
    output_key="google_search_results" # Save result to a unique key
)

# This ParallelAgent runs both searches AT THE SAME TIME.
ParallelSearchAgent = ParallelAgent(
    name="ParallelSearchAgent",
    sub_agents=[DatabaseSearchAgent, GoogleSearchAgent]
)

# This agent's job is to intelligently combine the results.
SynthesizerAgent = LlmAgent(
    name="SynthesizerAgent", model="gemini-2.5-pro",
    instruction="You are an analyst. You have two pieces of information in the session state: "
                "1. 'database_groceries': A list of groceries the user actually bought. "
                "2. 'google_search_results': Search results for a specific item the user asked about. "
                "Your task is to synthesize these into one answer. "
                "PRIORITIZE the `google_search_results` if the user asked about a specific item. Answer their question directly using that info. "
                "If the user asked for a broad analysis, use the `database_groceries` list to provide insights. "
                "Present a comprehensive summary.",
    output_key="draft_answer"  # This is now a DRAFT, not the final answer.
)

# --- NEW: The Self-Correction Agent ---
ReviewerAgent = LlmAgent(
    name="ReviewerAgent",
    model="gemini-2.5-pro",
    instruction="You are a meticulous review agent. Your job is to critique and refine a draft answer. "
                "You will be given the user's original request from the 'last_user_message' state key and a 'draft_answer'. "
                "Critically evaluate the 'draft_answer' based on these rules: "
                "1. Spirit of the Prompt: Does it fully and enthusiastically answer the user's original request? "
                "2. Repetitiveness: Is the language concise and not repetitive? "
                "3. Helpfulness: Is the answer genuinely helpful and easy to understand? "
                "If the draft is perfect, output it as is. If it has flaws, REWRITE it to be better and output the improved version. This is the final answer."
                "Egg is considered non veg",
    output_key="final_analysis_summary"
)
# This SequentialAgent defines the full, robust workflow.
HealthBudgetAnalystToolAgent = SequentialAgent(
    name="HealthBudgetAnalystTool",
    description="Use this tool to analyze a user's groceries for health and budget insights. It can analyze their purchase history OR a specific item they ask about by searching both the database and the web in parallel.",
    sub_agents=[
        ParallelSearchAgent,  # Step 1: Search in parallel
        SynthesizerAgent,     # Step 2: Create a draft answer
        ReviewerAgent         # Step 3: Review, rethink, and finalize the answer
    ]
)