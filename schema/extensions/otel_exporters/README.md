# OpenTelemetry Exporters Extension

## Overview

The OpenTelemetry Exporters extension provides standardized schemas for configuring how AGNTCY agents export their observability data to various backends. This extension complements the existing AGNTCY Observability Data Schema by defining how the collected telemetry data should be exported.

## Purpose

While the AGNTCY Observability Data Schema defines WHAT data to collect (metrics, traces, events), this extension defines HOW and WHERE to send that data. It provides:

1. **Standardized Export Configurations**: Consistent way to configure exporters across all agents
2. **Multi-Backend Support**: Export to various observability platforms (Prometheus, Jaeger, Datadog, etc.)
3. **Pipeline Management**: Configure complete observability pipelines with processors and exporters
4. **Security**: Built-in authentication and TLS configurations

## Key Components

### 1. Exporter Configuration (`otel_exporter_config`)

Defines configuration for individual exporters:
- **Exporter Types**: OTLP, Prometheus, Jaeger, Zipkin, Datadog, New Relic, etc.
- **Endpoints**: Where to send the data
- **Authentication**: API keys, tokens, OAuth2, mTLS
- **Performance**: Batching, compression, retry logic

### 2. Pipeline Configuration (`otel_pipeline_config`)

Complete pipeline setup for telemetry data:
- **Pipeline Types**: Traces, Metrics, Logs, or All
- **Processors**: Transform data before export
- **Sampling**: Manage data volume and costs
- **Error Handling**: How to handle export failures

### 3. Authentication (`otel_auth_config`)

Comprehensive authentication options:
- API Key
- Bearer Token
- Basic Auth
- OAuth2
- Mutual TLS

### 4. Performance Optimization

- **Batching** (`otel_batch_config`): Optimize network usage
- **Retry** (`otel_retry_config`): Handle transient failures
- **Sampling** (`otel_sampling_config`): Control data volume

## Usage Example

An agent implementing this extension would declare in its manifest:

```json
{
  "agent": {
    "name": "my-agent",
    "features": {
      "observability": {
        "otel_export": {
          "pipelines": [
            {
              "pipeline_name": "production-traces",
              "pipeline_type": "traces",
              "enabled": true,
              "sampling_config": {
                "sampling_strategy": "trace_id_ratio",
                "sampling_rate": 0.1
              },
              "exporters": [
                {
                  "exporter_type": "otlp",
                  "endpoint": "https://otel-collector.example.com:4317",
                  "protocol": "grpc",
                  "authentication": {
                    "auth_type": "api_key",
                    "api_key": "${OTEL_API_KEY}"
                  },
                  "compression": "gzip",
                  "retry_config": {
                    "enabled": true,
                    "initial_interval": 5,
                    "max_interval": 300,
                    "max_elapsed_time": 900
                  }
                }
              ]
            },
            {
              "pipeline_name": "metrics-monitoring",
              "pipeline_type": "metrics",
              "enabled": true,
              "exporters": [
                {
                  "exporter_type": "prometheus",
                  "endpoint": "http://prometheus:9090/api/v1/write",
                  "protocol": "http"
                }
              ]
            }
          ]
        }
      }
    }
  }
}
```

## Integration with AGNTCY Observability

This extension works with the existing AGNTCY observability schema:

1. **Data Collection**: AGNTCY Observability Schema defines the telemetry data
2. **Data Export**: This extension defines how to export that data
3. **Complete Solution**: Together they provide end-to-end observability

## Benefits

1. **Standardization**: All agents use the same export configuration format
2. **Flexibility**: Support for multiple backends and protocols
3. **Production Ready**: Built-in retry, batching, and error handling
4. **Security**: Comprehensive authentication options
5. **Cost Management**: Sampling strategies to control data volume

## Supported Backends

- **OTLP**: OpenTelemetry Protocol (recommended)
- **Prometheus**: For metrics
- **Jaeger/Zipkin**: For distributed tracing
- **Commercial APMs**: Datadog, New Relic, Elastic APM
- **Cloud Providers**: AWS X-Ray, Google Cloud Operations, Azure Monitor

## Best Practices

1. **Use OTLP when possible**: It's the most future-proof option
2. **Configure sampling**: Control costs in production
3. **Set up retry logic**: Handle transient network issues
4. **Use compression**: Reduce bandwidth usage
5. **Secure exports**: Always use authentication and TLS

## Future Enhancements

- Support for custom exporters
- Advanced routing based on telemetry attributes
- Cost estimation based on configuration
- Auto-discovery of collector endpoints
- Export health monitoring

## Contributing

To add support for new exporters or enhance existing ones:
1. Add new exporter types to `otel_exporter_config`
2. Document authentication requirements
3. Provide configuration examples
4. Test with real backends

## Version History

- **1.0.0**: Initial release with support for major observability platforms