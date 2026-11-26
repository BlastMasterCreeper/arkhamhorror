//! External Catalog: FlowId → Flow body (Eff). Not part of Snapshot.

use std::collections::BTreeMap;

use crate::eff::Eff;

#[derive(Clone, Debug)]
pub struct Flow {
    pub id: String,
    pub body: Eff,
}

#[derive(Clone, Debug, Default)]
pub struct Catalog {
    flows: BTreeMap<String, Flow>,
}

impl Catalog {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn insert(&mut self, id: String, flow: Flow) {
        self.flows.insert(id, flow);
    }

    pub fn get(&self, id: &str) -> Option<&Flow> {
        self.flows.get(id)
    }
}
