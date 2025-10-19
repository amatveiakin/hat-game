import yaml


class FlowListDumper(yaml.SafeDumper):
    def represent_sequence(self, tag, sequence, flow_style=None):
        processed_sequence = [self.represent_data(item) for item in sequence]
        return yaml.SequenceNode(tag, processed_sequence, flow_style=True)

    def represent_str(self, data):
        return self.represent_scalar("tag:yaml.org,2002:str", data, style='"')


FlowListDumper.add_representer(str, FlowListDumper.represent_str)
