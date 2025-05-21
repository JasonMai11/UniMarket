import Foundation

struct University: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let state: String
    
    static let universities: [University] = [
        // California Universities
        University(name: "University of California, Berkeley", state: "CA"),
        University(name: "University of California, Los Angeles", state: "CA"),
        University(name: "University of California, San Diego", state: "CA"),
        University(name: "Stanford University", state: "CA"),
        University(name: "University of Southern California", state: "CA"),
        University(name: "California Institute of Technology", state: "CA"),
        
        // New York Universities
        University(name: "University at Buffalo", state: "NY"),
        University(name: "Buffalo State University", state: "NY"),
        University(name: "SUNY Buffalo State", state: "NY"),
        University(name: "New York University", state: "NY"),
        University(name: "Columbia University", state: "NY"),
        University(name: "Cornell University", state: "NY"),
        University(name: "Syracuse University", state: "NY"),
        University(name: "University of Rochester", state: "NY"),
        
        // Massachusetts Universities
        University(name: "Harvard University", state: "MA"),
        University(name: "Massachusetts Institute of Technology", state: "MA"),
        University(name: "Boston University", state: "MA"),
        University(name: "Boston College", state: "MA"),
        University(name: "University of Massachusetts Amherst", state: "MA"),
        
        // Texas Universities
        University(name: "University of Texas at Austin", state: "TX"),
        University(name: "Texas A&M University", state: "TX"),
        University(name: "Rice University", state: "TX"),
        University(name: "University of Houston", state: "TX"),
        
        // Illinois Universities
        University(name: "University of Illinois at Urbana-Champaign", state: "IL"),
        University(name: "University of Chicago", state: "IL"),
        University(name: "Northwestern University", state: "IL"),
        
        // Michigan Universities
        University(name: "University of Michigan", state: "MI"),
        University(name: "Michigan State University", state: "MI"),
        
        // Pennsylvania Universities
        University(name: "University of Pennsylvania", state: "PA"),
        University(name: "Penn State University", state: "PA"),
        University(name: "Carnegie Mellon University", state: "PA"),
        
        // Florida Universities
        University(name: "University of Florida", state: "FL"),
        University(name: "Florida State University", state: "FL"),
        University(name: "University of Miami", state: "FL"),
        
        // Washington Universities
        University(name: "University of Washington", state: "WA"),
        University(name: "Washington State University", state: "WA"),
        
        // Oregon Universities
        University(name: "University of Oregon", state: "OR"),
        University(name: "Oregon State University", state: "OR")
    ]
    
    static func searchUniversities(query: String) -> [University] {
        if query.isEmpty {
            return []
        }
        
        let searchTerms = query.lowercased().split(separator: " ")
        return universities.filter { university in
            let universityName = university.name.lowercased()
            return searchTerms.allSatisfy { term in
                universityName.contains(term)
            }
        }
    }
} 