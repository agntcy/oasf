# AGNTCY Observability Data Schema

## Introduction

This document describes the AGNTCY Observability Data Schema, an extension of the Open Telemetry (OTel) framework, following the LLM Semantic Conventions for Generative AI systems.  This schema is designed to provide comprehensive observability for Multi-Agent Systems (MAS), enabling detailed monitoring, analysis, and evaluation of their performance and behavior.

AGNTGY.org is releasing this schema to facilitate standardized observability across diverse agentic systems. It is enriched with MAS-specific concepts, such as agent collaboration success rate, MAS response time, and task delegation accuracy.

## Goal

The primary goal of this schema is to provide a standardized structure for Observability SDKs to implement, ensuring consistent data capture and reporting across diverse agentic systems implemented in various frameworks.

## Key Components of the Schema

The AGNTCY Observability Data Schema encompasses three primary data types: Metrics, Traces, and Events.

### 1. Metrics

Metrics are numerical measurements captured over time, providing insights into the performance and resource utilization of the system. The schema defines a set of metrics covering various aspects of Generative AI clients and servers.

**AGNTCY Contributions (IoA-Specific Metrics):**

AGNTGY is contributing the following metrics (identified by `ioa` in their names) to provide detailed insights into the performance and behavior of Intelligent Open Agents:

*   **`gen_ai.client.ioa.response_latency`**: Measures the end-to-end response time for the client to receive agent execution results (in seconds).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
*   **`gen_ai.client.ioa.agent.response_latency`**: Measures the time taken by the agent to complete its execution and return a result (in seconds).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
*   **`gen_ai.client.ioa.agent.end_to_end_chain_completion_time`**: Measures the time taken by an agent to complete a full sequence of chained tasks in a workflow (in seconds).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.client.ioa.agent.execution_success_rate`**: Represents the fraction of agent executions that complete successfully without errors (ratio).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.client.ioa.agent.error_count`**: Counts the total number of errors encountered by the agent.
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.client.ioa.agent.uptime_and_availability`**: Represents the percentage of time the agent is operational and available (percentage).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.client.ioa.agent.error_recovery_rate`**: Represents the fraction of agent failures that successfully recover without external intervention (ratio).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.client.ioa.agent.task_delegation_accuracy`**: Measures how accurately the semantic router delegates tasks to the correct agent (ratio).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.client.ioa.agent.connection_reliability`**: Represents the success rate of establishing authenticated connections between agents (ratio).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.client.ioa.agent.transfer_time_accuracy`**: Measures the accuracy and timeliness of data transfer between agents (ratio).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.client.ioa.agent.collaboration.success_rate`**: Represents the fraction of multi-agent collaborations that complete successfully (ratio).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.server.ioa.agp.chain_completion_time`**: Measures the time taken for a message to be routed from one agent to another and optionally back, via the AGP gateway (in seconds).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.server.ioa.agp.connection_latency`**: Measures the latency involved in connecting to the AGP gateway and establishing routes or subscriptions (in seconds).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.server.ioa.agp.error_rates`**: Counts the total number of errors encountered within the AGP layer (e.g., message handling, routing failures).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
 *   **`gen_ai.server.ioa.agp.message_throughput`**: Tracks the rate of messages sent and received over the AGP, reflecting communication load (messages/second).
  *   Attributes:
        *   `metric_version`: The version of the metric being reported.
        *   `processing_mode`: The mode of processing for the request (real-time, batch, on-demand).
        *   `reporting_frequency`: The frequency at which the latency is reported (daily, per-task, real-time, on-demand).
        *   `collection_method`: The method used to collect the latency data (instrumentation, manual logs, OTel).
        *   `outcome_justification`: The justification for the outcome of the request.
     
**Standard Metrics:**

*   `gen_ai.client.token.usage`: Counts the number of input and output tokens used by the generative AI client (count).
*   `gen_ai.client.operation.duration`: Measures the duration of operations initiated by the generative AI client (seconds).
*   `gen_ai.server.request.duration`: Measures the duration of requests processed by the generative AI server (seconds).
*   `gen_ai.server.time_per_output_token`: Measures the time taken to generate each output token after the first one (seconds).
*   `gen_ai.server.time_to_first_token`: Measures the time taken to generate the first token in a successful response (seconds).
*   `llm.openai.chat_completions.exceptions`: Time to first token in streaming chat completions (seconds).
*   `llm.openai.chat_completions.streaming_time_to_first_token`: Time to first token in streaming chat completions (seconds).
*   `llm.openai.chat_completions.streaming_time_to_generate`: Time between first token and completion in streaming chat completions (seconds).

### 2. Traces

Traces represent the end-to-end flow of a request through the system, providing a detailed view of the sequence of operations and their timing.  The schema defines a set of attributes to capture relevant information about each span within a trace.

**Key Attributes:**

*   `gen_ai.operation.name`: The name of the operation being performed (e.g., `chat`, `text_completion`, `embeddings`).
*   `gen_ai.system`: The Generative AI product as identified by the client or server instrumentation (e.g., `openai`, `langchain`).
*   `error.type`: Describes a class of error the operation ended with (e.g., `timeout`, `java.net.UnknownHostException`, `500`).
*   `gen_ai.agent.description`: Free-form description of the GenAI agent provided by the application.
*   `gen_ai.agent.id`: The unique identifier of the GenAI agent.
*   `gen_ai.agent.name`: Human-readable name of the GenAI agent provided by the application.
*   `gen_ai.output.type`: Represents the content type requested by the client (e.g., `text`, `json`, `image`).
*   `gen_ai.request.*`: Attributes related to the request parameters (e.g., `model`, `seed`, `temperature`, `top_p`, `max_tokens`).
*   `gen_ai.response.*`: Attributes related to the response from the GenAI model (e.g., `id`, `model`, `finish_reasons`).
*   `gen_ai.usage.*`: Attributes related to token usage (e.g., `input_tokens`, `output_tokens`).
*   `server.address`: GenAI server address.
*   `server.port`: GenAI server port.

**AGNTCY Contributions (IoA-Specific attributes):**

*   `gen_ai.ioa.agp.message_trace`: Track the path of a message from sending to receiving, which can help in diagnosing delays or failures in message routing.
*   `gen_ai.ioa.agp.performance_trace`: Tracing to capture performance-related data, like processing time for different operations within the gateway and agent.
*   `gen_ai.ioa.span_kind`: The kind of span being recorded, such as client, server, producer, or consumer.
*   `gen_ai.ioa.start_condition`: The condition under which the span starts, such as which agent or tool initiated the action.
*   `gen_ai.ioa.end_condition`: The condition under which the span ends, such as which agent or tool completed the action.
*   `gen_ai.ioa.collection_method`: The method used to collect the trace data.
*   `gen_ai.ioa.sampling_rate`: The rate at which data is sampled, percentage of traces retained for analysis.

### 3. Events

Events represent discrete occurrences of interest within the system, such as user messages, model choices, and tool executions. The schema defines a set of events with specific attributes to capture relevant details.

**Key Events:**

*   `gen_ai.system.message`: Describes the instructions passed to the Generative AI model.
    *   Attributes:
        *   `role`: Role of the message author.
        *   `content`: The message content.
*   `gen_ai.user.message`: Describes the user-specified prompt message.
    *   Attributes:
        *   `role`: Role of the message author.
        *   `content`: The message content.
*   `gen_ai.choice`: Describes model-generated chat response (choice).
    *   Attributes:
        *   `finish_reason`: Why the model stopped generating tokens.
        *   `index`: Index of the choice in the list.
        *   `message`: Response message including `role`, `content`, and `tool_calls`.
*   `gen_ai.tool.message`: Describes the response from a tool or function call passed to the GenAI model.
*   `db.query.embeddings`: Logs query embeddings.
*   `db.query.result`: Logs query result.

**AGNTCY Contributions (IoA-Specific events):**

*   `gen_ai.ioa.generic`: Generic event for tracking agent interactions.

    *   **Attributes:**
        *   `error_message`: Error message associated with the agent.
        *   `status_code`: Status code, if applicable.
        *   `event_type`: The type of the event.
        *   `event_source`: The source of the event.
        *   `agent_id`: The ID of the agent.
        *   `agent_role`: The role of the agent.
        *   `agent_version`: The version of the agent.
        *   `input_data`: The input data for the event.
        *   `output_data`: The output data for the event.
        *   `tool_used`: The tool used in the event.
        *   `recipient_agent_id`: The ID of the recipient agent.
        *   `channel`: The communication channel used.
        *   `status`: The status of the event.
        *   `error_code`: The error code, if any.
        *   `retry_attempt`: The number of retry attempts.
        *   `policy_triggered`: The policy triggered by the event.
        *   `policy_decision`: The decision made by the policy.

## Conclusion

The AGNTCY Observability Data Schema provides a comprehensive and extensible framework for monitoring and analyzing Generative AI systems, particularly Multi-Agent Systems. By adopting this schema, developers and operators can gain deeper insights into the behavior of their systems, enabling them to optimize performance, improve reliability, and ensure the quality of AI-driven applications.