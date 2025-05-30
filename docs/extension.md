# Critical Reflection and Extension Proposal
During the release engineering process of the restaurant sentiment-analysis project, we observed several shortcomings that limited reliability and efficiency of development. To address this, we critically reflect on the current state of the project and propose an enhancement focusing on the provisioning process.

### 1. Critical Reflection on Shortcomings
At the current state of the restaurant sentiment-analysis project, key shortcomings identified include the following:
1. **Flaky provisioning:** Our provisioning pipeline is frequently subject to failure due to race conditions, instability, limited idemptoncy, and possibly hardware specifications. As a result, developers were often forced to destroy and recreate environmentments manually, and developers faced difficulty in debugging provisioning scripts. Arguably, this was the leading cause of delay and failure during the development process thus far.
2. **Manual dependency management:** Dependencies across services are handled manually and inconsistenly. This results in mismatched libraries, outdated packages, and increased risk of security vulnerabilities.
3. **Manual rollbacks:** When performing A/B testing for continous development, there is no automation for rollbacks. As such, developers must be responsible for failure detection and version rollbacks which increases operational burder and increases problem resolution speeds.
4. **Lack of integration testing:** System-level interactions between services are not tested before deployment. Therefore, bugs such as incompatible APIs and faulty inter-service communication can enter production (Shahin et al., 2017).
5. **Limited automated testing:** Many repositories, such as the [app](https://github.com/remla25-team6/app) repository, lack automated unit tests, in addition to linters enforcing code quality and test coverage. The absence of such tests and tools leads to code being merged and deployed without confidence in its functionality (Polo et al., 2013). Developers will need to rely on manual testing or post-deployment bug-fixes, which may increase lead time or hinder CI/CD effectiveness.
6. **Not truly distributed architecture:** While our environment simulates a distributed system on a single host using virtual machine, the architecture is not truly distributed on different hosts. This masks potential issues with network latency and inter-node communication, while possibly increasing fault tolerance (Padvekar, 2024).

### 2. Focus: Flaky Provisioning
Due to the persistant issue of flaky provisioning that our team encountered throughout the development lifecycle, we focus on this shortcoming for the rest of this report. The current approach uses Vagrant and Ansible to deploy a local multi-node Kubernetes cluster (see *deployment.md* for more details). The cluster constitutes of one control node(`ctrl`) with multiple worker nodes dictated by a Vagrantfile with Ansible playbooks per role. 

In theory, this approach ensures consistent environments but, in practice, we have observed that the provisioning process is fragile and error-prone. While we do not definitively know the source behind these recurrent issues, we suspect the problems can be isolated to three possible root problems: non-idempotent provisioning states, debuggability issues, and playbooking timing and synchronization. With regards to non-idempotent states, the current provisioning process does not gracefully support re-runs. If any part fails, the user is often forced to destroy the environment and re-provision, or at least re-run provisioning from scratch. Additionally, debugging has been observed to be difficult and hard to trace due to lack of detailed logging upon failure. Finally, the provisioning sequence relies on Vagrant to invoke Ansible individually per virtual machine, which can make synchronization difficult. For example, if the playbooks for the control nodes and worker nodes are run simultaneously but are not fully stable before the clusters are joined, this could result in errors.

### 3. Solution Proposal
We propose a two-fold approach to address the issue of flaky provisioning. This consists of migrating the infrastructure layer to Terraform and implementing automated end-to-end testing for provisioning. We expand on this further in the subsequent sections.

#### 3.1. Terraform
Terraform (Hashicorp, n.d.) is an infrastructure as code tool that lets you build, change, and version infrastructure safely and efficiently (Hashicorp, 2025). To address environment consistency and unexpected host-dependent configurations, we replace Vagrant with Terraform as the tool for provisioning. Fadaei (2024) describes how Vagrant is a nice tool primarily focused on setting up local development environments, but it lacks the broader capabilities required for production-grade infrastructure. He argues that Terraform, on the other hand, is a professional-grade, widely adopted tool with a vast community, extensive documentation, and support for managing cloud and on-premises infrastructure. Its flexibility and scalability surpass Vagrant’s, making it a cornerstone tool in modern DevOps practices. 

Terraform will declare the virtual-machine specs, network layout, and shared folders in code that lives in version control, so the entire stack can be recreated identically on any machine. As with Vagrant, we keep the roles clear: Terraform defines the infrastructure, while Ansible handles the inside-VM configuration.

We’ll add Terraform provisioner (Hashicorp, n.d.) blocks to enforce the build order. First, the control-plane VM is deployed, initialises Kubernetes, and writes the `kubeadm` join command to shared state. Once that command exists, the worker VMs start and use it to join the cluster.Because Terraform tracks a state file, it can calculate the diff between the desired and actual infrastructure, resume safely after a partial failure, and avoid a full teardown in most cases. By modelling the control-plane and worker pools as separate modules, we gain reusable, easily testable building blocks. Finally, Terraform’s structured logs make troubleshooting more straightforward.

#### 3.2. End-to-End Provisioning Testing
Additionally, due to flaky provisioning, we integrate automated end-to-end testing to validate cluster readiness. After launching via Terraform and running Ansible playbooks using Terraform provisioners, we validate post-setup:
1. Nodes are ready.
2. Application is deployed and ready.
3. MetalLB IP is functioning.
4. Pods respond to test requests.
5. Run `kube-bench` to validate security compliance.
6. Run `kube-linter` to validate quality.
7. Assert idempotency by re-running Terraform. We expect 0 changes.

### 4. Experimental Design
To check whether the proposed solution solves the issue of flaky provisioning, we design an empirical experiment to validate this. Specifically, to evaluate improvements in reliability and stability, we perform 10 end-to-end provisioning cycles using the new setup across multiple machines (to isolate host dependencies). During this process, we collect the following metrics:
- **Success rate:** Percentage of provisioning runs that complete without failure.
- **Time:** Total time from start to end of provisioning.
- **Cluster health:** Verify clusters are correctly deployed using custom health-checking scripts.
- **Idempotence check:** Number of changes when re-running provisioning with the same Ansible playbooks. In the optimal scenario, we expect 0 changes if truly idempotent.
- **Test success rate:** Ratio of passing tests from end-to-ending tests.

Based on these metrics, we can validate whether the proposed solution has the desired outcomes.

### 5. Conclusion
In conclusion, we identified 6 shortcomings releated to release engineering in the current state of our sentiment-analysis application. We stress that flaky provisioning is the most frequently encountered issue and propose adopting Terraform instead of Vagrant, and employing end-to-end testing to improve upon the current release strategy. These changes aim to improve reproducability, idempotency and developer workflows. 

### References
1. Fadaei, M. R. (2024, November 26). Vagrant and VirtualBox are no longer enough: Why KVM and Terraform are the future of DevOps. Medium. https://medium.com/@mohrezfadaei/vagrant-and-virtualbox-are-no-longer-enough-why-kvm-and-terraform-are-the-future-of-devops-24f978c9ca2c
2. HashiCorp. (n.d.). Provisioners. HashiCorp Developer. https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax
3. HashiCorp. (n.d.). Terraform. HashiCorp Developer. https://developer.hashicorp.com/terraform
4. Padvekar, A., & Gupta, V. (2024). Comparative analysis of monolithic vs. distributed architecture. International Journal of Advanced Research in Science, Communication and Technology, 433–442. https://doi.org/10.48175/IJARSCT-18946
5. Polo, M., Reales, P., Piattini, M., & Ebert, C. (2013). Test automation. IEEE Software, 30(1), 84–89. https://doi.org/10.1109/MS.2013.15
6. Shahin, M., Ali Babar, M., & Zhu, L. (2017). Continuous integration, delivery and deployment: A systematic review on approaches, tools, challenges and practices. IEEE Access, 5, 3909–3943. https://doi.org/10.1109/ACCESS.2017.2685629

### AI Disclaimer
This text was refined using ChatGPT o3, but all ideas are original and belong to the authors.