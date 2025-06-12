# A1. Versions, Releases & Containerization
### Basic Requirements
1. **Data Requirements:** Pass ✅
2. **Sensible Use Case:** Pass 🟡
    - User input is leveraged for validation or growing dataset (not yet connected).

### Versioning and Releases
1. **Automated release process:** Excellent ✅
2. **Software reuse in libraries:** Excellent ✅

### Containers and Orchestration
1. **Exposing a model via REST:** Excellent ✅
2. **Docker compose operation:** Excellent ✅

# A2. Provisioning & Kubernetes
### Provisioning
1. **Setting up (Virtual) Infrastructure:**  Excellent ✅
3. **Setting up Software Environment:** Excellent ✅
5. **Setting up Kubernetes:** Excellent ✅
  
# A3. Operate & Monitor Kubernetes
### Kubernetes & Monitoring
1. **Kubernetes Usage**: Excellent ✅
2. **Helm Installation:** Excellent ✅
3. **App Monitoring:** Good 🟡
    - Each metric types has at least one example, in which the metric is broken down with labels.
5. **Grafana:** Excellent ✅

# A4. ML Testing and Config Management
### ML Testing:
1. **Automated Tests:** Excellent ✅
3. **Continous Training:** Excellent ✅

### ML Configuration Management
1. **Project Organization:** Excellent ✅
2. **Pipeline Management with DVC:** Excellent ✅
4. **Code Quality:** Excellent ✅
  
# A5. Istio Service Mesh
### Implementation
1. **Traffic Management:** Excellent ✅
2. **Additional Use Case:** Insufficient ❌
    - An additional use case has been attempted, but it does not work.
    - One of the described use cases has been partially realized, with observable effects.
    - One of the described use cases has been realized. It generally works, but falls short in some aspects.
    - One of the described use cases has been fully realized.
3. **Continous Experimentation:** Insufficient ❌
    - An experiment is attempted, but lacks either sufficient documentation or implementation.
    - The documentation describes the experiment. It explains the implemented changes, the expected effect that gets experimented on, and the relevant metric that is tailored to the experiment:
    - The experiment involves two deployed versions of at least one container image.
    - Both component versions are reachable through the deployed experiment.
    - The system implements the metric that allows exploring the concrete hypothesis.
    - Prometheus picks up the metric.
    - Grafana has a dashboard to visualize the differences and support the decision process.
    - The documentation contains a screenshot of the visualization
    - The documentation explains the decision process for accepting or rejecting the experiment in details, ie.g., which criteria is used and how the available dashboard supports the decision.

### Documentation
1. **Deployment Documentation:** Insufficient ❌
    - The documentation is limited to the deployment structure or the data flow.
    - The documentation describes the deployment structure, i.e., the entities and their connections.
    - The documentation describes the data flow for incoming requests.
    - The documentation contains visualizations that are connected to the text.
    - The documentation includes all deployed resource types and relations.
    - The documentation is visually appealing and clear.
    - A new team member could contribute in a design discussion after studying the documentation.
3. **Extension Proposal:** Excellent ✅
