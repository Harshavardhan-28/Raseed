# File: MY_RECIPE_AGENT/recipe_agent/agent.py

from google.adk.agents import LlmAgent, SequentialAgent, BaseAgent
from google.adk.tools import agent_tool
from google.adk.agents.invocation_context import InvocationContext
from typing import AsyncGenerator
from google.adk.events import Event, EventActions
from . import tools # Keep this
# We no longer need the callbacks import
from .subsystems.recipe_generator import RecipeGeneratorToolAgent
from .subsystems.health_analyst import HealthBudgetAnalystToolAgent

class ContentSaverAgent(BaseAgent):
    """A simple agent that saves the initial user message to session state."""
    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        if ctx.user_content and ctx.user_content.parts and ctx.user_content.parts[0].text:
            user_text = ctx.user_content.parts[0].text
            state_delta = {"last_user_message": user_text}
            yield Event(author=self.name, actions=EventActions(state_delta=state_delta))
        return

wallet_agent = LlmAgent(
    name="WalletAgent", model="gemini-2.0-flash",
    description="Adds missing grocery items to the user's Google Wallet when requested.",
    instruction="Use the 'add_to_google_wallet' tool for user 'ZFW7wDV8Exap8FLXGLH5C0TL9NH3'.",
    tools=[tools.add_to_google_wallet]
)

MainOrchestratorAgent = LlmAgent(
    name="MainOrchestratorAgent",
    model="gemini-2.0-flash",
    instruction="You are a brilliant receipt management and culinary assistant. Your job is to understand the user's goal (from the 'last_user_message' state key) and use the correct tool. "
                "- If they ask for a recipe, use the `RecipeGeneratorTool`. "
                "- If they ask for analysis or insights, use the `HealthBudgetAnalystTool`. "
                "- After a tool is used, if the user wants to add items to a shopping list, use the `WalletAgent` tool. "
                "Synthesize all information into a single, helpful, and conversational response.",
    tools=[
        agent_tool.AgentTool(agent=RecipeGeneratorToolAgent),
        agent_tool.AgentTool(agent=HealthBudgetAnalystToolAgent),
        agent_tool.AgentTool(agent=wallet_agent)
    ]
    # The callbacks that were causing the crash have been removed for stability.
)

root_agent = SequentialAgent(
    name="MainChatbotAgent",
    sub_agents=[
        ContentSaverAgent(name="ContentSaver"),
        MainOrchestratorAgent
    ]
)