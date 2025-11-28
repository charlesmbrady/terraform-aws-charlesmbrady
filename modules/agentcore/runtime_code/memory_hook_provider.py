"""
Memory Hook Provider for AgentCore Runtime
Handles conversation history storage and retrieval using AWS Bedrock AgentCore Memory API
"""

from bedrock_agentcore.memory import MemoryClient
from strands.hooks.events import AgentInitializedEvent, MessageAddedEvent
from strands.hooks.registry import HookProvider, HookRegistry
import copy


class MemoryHook(HookProvider):
    """
    Manages conversation memory for the agent.
    Loads recent conversation history when agent initializes.
    Stores new messages to memory after each turn.
    """

    def __init__(
        self,
        memory_client: MemoryClient,
        memory_id: str,
        actor_id: str,
        session_id: str,
    ):
        self.memory_client = memory_client
        self.memory_id = memory_id
        self.actor_id = actor_id
        self.session_id = session_id
        print(
            f"[MemoryHook] Initialized - memory_id={memory_id}, actor={actor_id}, session={session_id}"
        )

    def on_agent_initialized(self, event: AgentInitializedEvent):
        """Load recent conversation history when agent starts"""
        try:
            print(
                f"[MemoryHook] Loading conversation history for session {self.session_id}"
            )

            # Load the last 5 conversation turns from memory
            recent_turns = self.memory_client.get_last_k_turns(
                memory_id=self.memory_id,
                actor_id=self.actor_id,
                session_id=self.session_id,
                k=5,  # Get last 5 conversation turns
            )

            if not recent_turns:
                print("[MemoryHook] No previous conversation history found")
                return

            # Convert memory format to agent message format
            context_messages = []
            for turn in recent_turns:
                # Support different payload shapes from Memory API
                # Case A: turn is a dict with key "messages" (list of dicts)
                if (
                    isinstance(turn, dict)
                    and "messages" in turn
                    and isinstance(turn["messages"], list)
                ):
                    messages_list = turn["messages"]
                # Case B: turn itself is a list of message dicts
                elif isinstance(turn, list):
                    messages_list = turn
                else:
                    print(f"[MemoryHook] Unexpected turn shape: {type(turn)} - {turn}")
                    continue

                for message in messages_list:
                    if not isinstance(message, dict):
                        continue
                    msg_role = message.get("role") or message.get("type") or "user"
                    # Content may be nested { content: { text: ... } } or { content: [ { text: ... } ] }
                    content_text = None
                    if isinstance(message.get("content"), dict):
                        content_text = message["content"].get("text")
                    elif (
                        isinstance(message.get("content"), list) and message["content"]
                    ):
                        first = message["content"][0]
                        if isinstance(first, dict):
                            content_text = first.get("text")
                    elif isinstance(message.get("text"), str):
                        content_text = message.get("text")

                    if not content_text:
                        continue

                    role = "assistant" if msg_role == "assistant" else "user"
                    context_messages.append(
                        {"role": role, "content": [{"text": content_text}]}
                    )

            # Add context to agent's message history
            print(f"[MemoryHook] Loaded {len(context_messages)} previous messages")
            event.agent.messages = context_messages

            # Optionally enhance system prompt with context awareness
            event.agent.system_prompt += """

You have access to our conversation history. Use this context to:
- Maintain continuity across conversation turns
- Reference previously discussed topics
- Build on earlier answers
- Avoid repeating information unnecessarily
"""

        except Exception as e:
            print(f"[MemoryHook] Memory load error: {e}")
            # Don't fail the agent if memory load fails - just continue without history

    def on_message_added(self, event: MessageAddedEvent):
        """Store messages in memory after each turn"""
        messages = copy.deepcopy(event.agent.messages)

        try:
            # Only save user and assistant messages (not system/tool)
            if messages[-1]["role"] not in ["user", "assistant"]:
                return

            # Ensure message has text content
            if (
                not messages[-1].get("content")
                or not isinstance(messages[-1]["content"], list)
                or not messages[-1]["content"]
            ):
                return
            if "text" not in messages[-1]["content"][0]:
                return

            message_text = messages[-1]["content"][0]["text"]
            message_role = messages[-1]["role"]

            print(
                f"[MemoryHook] Saving {message_role} message to memory: {message_text[:50]}..."
            )

            # Save the conversation turn to memory
            self.memory_client.save_conversation(
                memory_id=self.memory_id,
                actor_id=self.actor_id,
                session_id=self.session_id,
                messages=[(message_text, message_role)],
            )

            print("[MemoryHook] Message saved successfully")

        except Exception as e:
            # Log but don't fail - memory save is not critical
            print(f"[MemoryHook] Memory save error: {e}")

    def register_hooks(self, registry: HookRegistry):
        """Register hook callbacks with the agent"""
        registry.add_callback(MessageAddedEvent, self.on_message_added)
        registry.add_callback(AgentInitializedEvent, self.on_agent_initialized)
