import ballerina/http;
import ballerina/sql;

service /api on new http:Listener(3000) {

    //Resouce Function to Retrieve all programmes due for review
    resource function get review_due() returns Reviews[]|error {
        stream<Reviews, sql:Error?> reviewsStream = db->query(`
            SELECT *
            FROM Reviews r
            WHERE r.review_due_date <= CURRENT_DATE
        `);

        Reviews[] reviewList = [];
        check from Reviews reviews in reviewsStream
            do {
                reviewList.push(reviews);
            };

        // if reviewList.length() == 0 {
        //     return error("No Programme is Due");
        // }

        return reviewList;
    }

    //Resource function to Delete a programme by programme code and returns the removed Programme.
    resource function delete delete_programme/[string programme_code]() returns Programmes[]|error {
        // Retrieve the programme details before deletion
        stream<Programmes, sql:Error?> programmeStream = db->query(`
        SELECT * 
        FROM Programmes
        WHERE programme_code = ${programme_code}
    `);

        Programmes[] programmeList = [];
        check from Programmes programme in programmeStream
            do {
                programmeList.push(programme);
            };

        // Check if the programme exists
        if programmeList.length() == 0 {
            return error("Programme not found.");
        }

        // First, delete related entries in the Courses table
        _ = check db->execute(`
        DELETE FROM Courses
        WHERE programme_code = ${programme_code}
    `);

        // Then, delete the programme
        _ = check db->execute(`
        DELETE FROM Programmes
        WHERE programme_code = ${programme_code}
    `);

        // Return the deleted programme details
        return programmeList;
    }

    //Resource function to Retrieve all programmes that belong to the same faculty
    resource function get faculty_programme/[string faculty]() returns Programmes[]|error {
        stream<Programmes, sql:Error?> programmeStream = db->query(`
            SELECT *
            FROM Programmes p
            WHERE p.faculty = ${faculty}
        `);

        Programmes[] programmeList = [];
        check from Programmes programme in programmeStream
            do {
                programmeList.push(programme);
            };

        // if reviewList.length() == 0 {
        //     return error("No Programme is Due");
        // }

        return programmeList;
    }
resource function put update_programme() returns error? {


string update_programme = "UPDATE Programmes SET programme_name = ?, NQF_level = ?, faculty = ?, department = ?, registration_date = ? WHERE programme_code = ?";
    
   
    var params = [
        programme.programme_name,
        programme.NQF_level,
        programme.faculty,
        programme.department,
        programme.registration_date,
        programme.programme_code
    ];

    
    sql:ExecutionResult result = check dbClient->execute(update_programme, params);

   
    if (result.affectedRowCount == 1) {
        io:println("Programme updated successfully!");
        return;
    } else {
        io:println("Error updating programme: ", result.sqlErrorCode, " - ", result.sqlErrorMessage);
        return error("Error updating programme");
    }
}

}
