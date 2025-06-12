import requests
import urllib3
import matplotlib.pyplot as plt
import numpy as np
import time 

URL = "https://192.168.56.92/"

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class sample_request:
    
    def __init__(self, URL, pr=0.05):
        self.URL = URL
        self.pr=pr
        self.cached_payload = "Some review to analyse that will be re-submitted with some probability"
        self.non_cached_payload = 1 # To ensure that no duplicates are sent on accident, this integer is incremented in every new request that DOESNT have a chaced hit.
        self.headerv1 = {
        'x-version': "v1"
        }
        self.headerv2 = {
        'x-version': "v2"
        }

        # Some variables to keep track of the state
        self.requests_sent = 0
        self.requests_v1 = 0
        self.requests_v2 = 0
        self.cached_sent_v1 = 0
        self.cached_sent_v2 = 0
    
    def send_with_prob(self):
        # Probability here refers to the probability that a cached input is provided (default = 5 percent)
        pr_repeat = np.random.random()

        # Send request to v1
        self.requests_v1 += 1
        _, input = self.send_v1(repeat=(self.pr > pr_repeat))

        # Send request to v2
        self.requests_v2 += 1
        _, _ = self.send_v2(repeat=(self.pr > pr_repeat))
        self.requests_sent += 1

        self.non_cached_payload += 1
        return (self.pr > pr_repeat), _, input
        
    # Send POST to image v1
    def send_v1(self, repeat=False):
        self.cached_sent_v1 += 1
        data = {
            'review': (str(self.non_cached_payload) if (not repeat) else self.cached_payload)
            }
        return requests.post(self.URL, headers=self.headerv1, data=data, verify=False), ((str(self.non_cached_payload) if (not repeat) else self.cached_payload))
    
    # Send POST to image v2
    def send_v2(self, repeat=False):
        self.cached_sent_v2 += 1
        data = {
            'review': (str(self.non_cached_payload) if (not repeat) else self.cached_payload)
            }
        return requests.post(self.URL, headers=self.headerv2, data = data, verify=False), ((str(self.non_cached_payload) if (not repeat) else self.cached_payload))
        
    def run_experiment(self, number_of_requests):
        for i in range (number_of_requests):
            was_cached, _, input = self.send_with_prob()
            print((bcolors.OKGREEN) + f"Sent a request to: {"v1"} with a {"cached" if was_cached else "non_cached"} input: {input}" + bcolors.ENDC)
            print((bcolors.OKCYAN) + f"Sent a request to: {"v2"} with a {"cached" if was_cached else "non_cached"} input: {input}" + bcolors.ENDC)
            time.sleep(0.3)
        print(bcolors.OKCYAN + f"Sent {self.requests_sent} total requests" + bcolors.ENDC)
        print(bcolors.OKCYAN + f"Sent {self.requests_v1} requests to V1 of which {self.cached_sent_v1} were repeat inputs" + bcolors.ENDC)
        print(bcolors.OKCYAN + f"Sent {self.requests_v2} requests to V2 of which {self.cached_sent_v2} were repeat inputs" + bcolors.ENDC)

        print(bcolors.OKCYAN + f"There was a 50% chance between v1/v2 and a probability of {self.pr} to repeat an input" + bcolors.ENDC)
    

def run():
    req = sample_request(URL, pr=0.9)
    req.run_experiment(5000)





if __name__ == "__main__":
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    run()
