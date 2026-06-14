pipeline {
    agent any

    environment {
        // Your Snowflake Account Identifier
        SNOWFLAKE_ACCOUNT = 'qwlsuhj-wf00414'
        
        // Service user details from our setup script
        SNOWFLAKE_USER = 'JENKINS_USER'
        SNOWFLAKE_ROLE = 'JENKINS_ROLE'
        SNOWFLAKE_WAREHOUSE = 'DATAOPS_WH'
        SNOWFLAKE_DATABASE = 'DATAOPS_DB'
        
        // This securely grabs the password from Jenkins Credentials Manager
        // and stores it in the SNOWFLAKE_PASSWORD environment variable
        SNOWFLAKE_PASSWORD = credentials('snowflake_password') 
    }

    stages {
        stage('Checkout Code') {
            steps {
                // This pulls the latest code from your GitHub repository
                checkout scm
            }
        }

        stage('Deploy to Snowflake') {
            steps {
                echo "Deploying to Snowflake account: ${env.SNOWFLAKE_ACCOUNT}"
                
                sh '''
                    # Create a Python virtual environment securely
                    python3 -m venv venv
                    . venv/bin/activate
                    
                    # Install schemachange
                    pip install --upgrade pip
                    pip install schemachange
                    
                    # Run the database migrations
                    schemachange -f migrations \\
                                 -a $SNOWFLAKE_ACCOUNT \\
                                 -u $SNOWFLAKE_USER \\
                                 -r $SNOWFLAKE_ROLE \\
                                 -w $SNOWFLAKE_WAREHOUSE \\
                                 -d $SNOWFLAKE_DATABASE \\
                                 -c $SNOWFLAKE_DATABASE.STAGING.CHANGE_HISTORY \\
                                 --create-change-history-table
                '''
            }
        }
    }
    
    post {
        success {
            echo '✅ Deployment to Snowflake was successful!'
        }
        failure {
            echo '❌ Deployment failed. Please check the Jenkins logs.'
        }
    }
}
