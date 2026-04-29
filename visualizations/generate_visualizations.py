from pathlib import Path

import matplotlib.pyplot as plt


OUT = Path(__file__).resolve().parent
OUT.mkdir(exist_ok=True)

plt.rcParams.update(
    {
        "figure.dpi": 180,
        "savefig.dpi": 220,
        "font.size": 10,
        "axes.titlesize": 13,
        "axes.labelsize": 10,
        "xtick.labelsize": 8,
        "ytick.labelsize": 8,
        "axes.spines.top": False,
        "axes.spines.right": False,
    }
)

INK = "#1A1C1E"
NAVY = "#16324F"
TEAL = "#1E6B5E"
AMBER = "#A76F00"
WARN = "#8A2C2C"
STEEL = "#5C6B7A"
MIST = "#EEF3F5"
PURPLE = "#6D5BA6"


def savefig(name: str) -> None:
    plt.tight_layout()
    plt.savefig(OUT / name, bbox_inches="tight", facecolor="white")
    plt.close()


def barh(labels, values, title, xlabel, filename, color=NAVY):
    fig, ax = plt.subplots(figsize=(9, 5.2))
    y = list(range(len(labels)))
    ax.barh(y, values, color=color)
    ax.set_yticks(y)
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    ax.set_title(title, color=INK, weight="bold")
    ax.set_xlabel(xlabel)
    ax.grid(axis="x", alpha=0.22)
    for idx, value in enumerate(values):
        ax.text(value, idx, f" {value:,}", va="center", color=INK, fontsize=8)
    savefig(filename)


def bar(labels, values, title, ylabel, filename, color=TEAL, rotate=25):
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.bar(labels, values, color=color)
    ax.set_title(title, color=INK, weight="bold")
    ax.set_ylabel(ylabel)
    ax.grid(axis="y", alpha=0.22)
    ax.tick_params(axis="x", rotation=rotate)
    for tick in ax.get_xticklabels():
        tick.set_ha("right")
    for idx, value in enumerate(values):
        suffix = "%" if "Percent" in ylabel or "%" in ylabel else ""
        ax.text(idx, value, f"{value:g}{suffix}", ha="center", va="bottom", fontsize=8)
    savefig(filename)


# 1. Graph scale by node label.
node_labels = [
    "Crime",
    "Location",
    "PostCode",
    "Officer",
    "Vehicle",
    "PhoneCall",
    "Person",
    "Phone",
    "Email",
    "Area",
    "Object",
]
node_counts = [28762, 14904, 14196, 1000, 1000, 534, 369, 328, 328, 93, 7]
barh(node_labels, node_counts, "POLE graph node distribution", "Nodes", "01_node_distribution.png")

# 2. Relationship distribution.
relationship_labels = [
    "OCCURRED_AT",
    "INVESTIGATED_BY",
    "HAS_POSTCODE",
    "LOCATION_IN_AREA",
    "POSTCODE_IN_AREA",
    "INVOLVED_IN",
    "KNOWS",
    "CALLER",
    "CALLED",
    "CURRENT_ADDRESS",
    "HAS_PHONE",
    "HAS_EMAIL",
    "KNOWS_SN",
    "FAMILY_REL",
    "KNOWS_PHONE",
    "KNOWS_LW",
    "PARTY_TO",
]
relationship_counts = [
    28762,
    28762,
    14904,
    14904,
    14196,
    985,
    586,
    534,
    534,
    368,
    328,
    328,
    241,
    155,
    118,
    80,
    55,
]
barh(
    relationship_labels,
    relationship_counts,
    "POLE graph relationship distribution",
    "Relationships",
    "02_relationship_distribution.png",
    color=TEAL,
)

# 3. Top repeat locations.
hotspots = [
    "Parking Area",
    "Supermarket",
    "Shopping Area",
    "Nightclub",
    "Petrol Station",
    "Sports/Recreation",
    "Piccadilly",
    "Pedestrian Subway",
    "Hospital",
    "Bus/Coach Station",
]
hotspot_counts = [811, 614, 594, 336, 331, 169, 166, 115, 113, 100]
barh(hotspots, hotspot_counts, "Top repeat crime locations", "Incidents", "03_top_hotspots.png", color=AMBER)

# 4. Outcome distribution.
outcomes = [
    "No suspect identified",
    "Unable to prosecute",
    "Under investigation",
    "Not public interest",
    "Awaiting court",
    "Local resolution",
]
outcome_share = [59.4, 17.8, 11.9, 4.1, 2.6, 1.6]
bar(outcomes, outcome_share, "Crime outcome distribution", "Share %", "04_outcome_distribution.png", color=NAVY)

# 5. Operational difficulty by crime type.
crime_types = [
    "Bicycle theft",
    "Vehicle crime",
    "Theft from person",
    "Burglary",
    "Robbery",
    "Other theft",
    "Criminal damage",
    "Public order",
]
unresolved = [96.6, 95.8, 95.5, 94.7, 89.8, 87.1, 81.6, 70.3]
barh(
    crime_types,
    unresolved,
    "Unresolved or no-suspect share by crime type",
    "Percent",
    "05_unresolved_by_crime_type.png",
    color=WARN,
)

# 6. Link viability audit.
link_families = [
    "Crime-Location",
    "Person-Person",
    "PhoneCall-Phone",
    "Vehicle-Crime",
    "Person-Location",
    "Person-Crime",
]
link_counts = [28762, 1180, 1068, 978, 368, 55]
barh(
    link_families,
    link_counts,
    "Observed links by candidate modelling surface",
    "Observed links",
    "06_link_viability_counts.png",
    color=PURPLE,
)

# 7. GML strategy comparison.
strategies = [
    "Social LP AUCPR",
    "Crime class F1",
    "Crime class accuracy",
    "Location baseline accuracy",
    "Area baseline accuracy",
    "Outcome baseline accuracy",
]
scores = [55.78, 14.41, 30.96, 32.3, 30.7, 61.5]
colors = [TEAL, WARN, WARN, AMBER, AMBER, NAVY]
fig, ax = plt.subplots(figsize=(9, 5))
ax.bar(strategies, scores, color=colors)
ax.set_title("Model and baseline comparison", color=INK, weight="bold")
ax.set_ylabel("Score %")
ax.grid(axis="y", alpha=0.22)
ax.tick_params(axis="x", rotation=25)
for tick in ax.get_xticklabels():
    tick.set_ha("right")
for idx, value in enumerate(scores):
    ax.text(idx, value, f"{value:.1f}%", ha="center", va="bottom", fontsize=8)
savefig("07_model_baseline_comparison.png")

# 8. Deployment gate / write-back summary.
labels = ["Supervised review", "Explainable review", "Supervised crime claims"]
values = [25, 4, 0]
fig, ax = plt.subplots(figsize=(7.5, 4.5))
ax.bar(labels, values, color=[TEAL, AMBER, WARN])
ax.set_title("Final write-back policy", color=INK, weight="bold")
ax.set_ylabel("Relationships written")
ax.grid(axis="y", alpha=0.22)
for idx, value in enumerate(values):
    ax.text(idx, value + 0.4, str(value), ha="center", fontsize=9)
savefig("08_writeback_policy.png")

# 9. Compact project scorecard table as an image.
fig, ax = plt.subplots(figsize=(10, 4.8))
ax.axis("off")
rows = [
    ["Total graph", "61,521 nodes / 105,840 relationships"],
    ["Strongest analytics surface", "28,762 Crime-Location links"],
    ["Hotspot concentration", "Top 10 locations cover 11.6% of incidents"],
    ["Social communities", "41 Louvain communities, modularity 0.6710"],
    ["Best supervised GML", "Social-family LP, RF, AUCPR 0.5578"],
    ["Review candidates", "25 supervised + 4 explainable links"],
    ["Negative ML result", "Crime-type classifier F1 0.1441"],
]
table = ax.table(
    cellText=rows,
    colLabels=["Result", "Value"],
    cellLoc="left",
    colLoc="left",
    loc="center",
)
table.auto_set_font_size(False)
table.set_fontsize(10)
table.scale(1, 1.7)
for (r, c), cell in table.get_celld().items():
    cell.set_edgecolor("#D4DCE2")
    if r == 0:
        cell.set_facecolor(NAVY)
        cell.set_text_props(color="white", weight="bold")
    elif r % 2 == 0:
        cell.set_facecolor(MIST)
ax.set_title("POLE project evidence scorecard", color=INK, weight="bold", pad=18)
savefig("09_project_scorecard.png")

print(f"Saved visualizations to {OUT}")
