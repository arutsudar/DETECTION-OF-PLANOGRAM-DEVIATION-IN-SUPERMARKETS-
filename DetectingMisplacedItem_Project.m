tic
clc;

folder = 'inputImages';   %type folder name here

if 7==exist('correct','dir')
    delete correct/*.jpg
else 
    mkdir correct
end    
if 7==exist('wrong','dir')
    delete wrong/*.jpg
else
    mkdir wrong
end    

dirImage = dir(folder); 
numFiles = size(dirImage,1); 
correct={};
wrong={};
printflag=0;
fileflag=0;
for i=1:numFiles
    fileflag=0;
    fname = dirImage(i).name;
    if regexp(fname, '[A-Za-z0-9-_,\s() ]+[.]+[jpg]')
        fileflag=1;
        A = imread(fname);
        AG=rgb2gray(A);
        [x,y] = size(AG);
        fprintf('\n');
        printflag=0;
        printsplits=-1;
        
        for splits=10:-1:2
            j=1;
            X=[];
            Z=[];
            for n = 1:splits
                tmp = AG(1:x, j:(j+ floor(y/splits) -1));
                I = mat2gray(tmp);
                points = detectSURFFeatures(I);
                [features, points] = extractFeatures(I, points);  %feature extraction          
                Z=cat(1,Z,size(features,1));
                X=cat(1,X,features);
                j = j + floor(y/splits);
            end

            a=1;
            answ=[];
            len=0;
            for n=1:splits
                len1=len;
                L=X( len+1          :  len+Z(n)          ,   :);
                for q=n+1:splits
                    M=X( len1+Z(q)+ 1  :  len1+Z(q-1)+Z(q)   ,   :);
                    pairs = matchFeatures(L,M);             %matched features
                    answ(a)=length(pairs);
                    a=a+1;
                    len1=len1+Z(q-1);
                end
                len=len+Z(n);
            end

            ANSWE=zeros(splits,1);
            a=1;
            for n=1:splits
                for q=n+1:splits
                    if(answ(a) <= 1)
                        ANSWE(n)=ANSWE(n)-1;
                        ANSWE(q)=ANSWE(q)-1;
                    end
                    if(answ(a) >= 10)
                        ANSWE(n)=ANSWE(n)+1;
                        ANSWE(q)=ANSWE(q)+1;
                    end
                    a=a+1;
                end
            end

            fprintf('%s ',fname);
            for n=1:splits
                fprintf('%d, ',ANSWE(n));
            end
            fprintf('\n');
            
            noZeros=0;
            noNeg=0;
            for n=1:splits
                if(ANSWE(n)==0)
                    noZeros=noZeros+1;
                elseif (ANSWE(n)<0)
                    noNeg=noNeg+1;
                    temp=n;
                end
            end
            
            temp1=sort(ANSWE(:));
            if((temp1(1)==-1*(splits-1) || temp1(1)==-1*(splits-2)) && temp1(2)-temp1(1)>=2 && noNeg<=splits-1)
                printflag=1;
                printsplits=splits;
                for n=1:splits
                    if(temp1(1)==ANSWE(n))
                        toprint=n;
                        fprintf('%s - Misplaced at %d\n ',fname,n);
                        break
                    end
                end
                break
            end
            
            if(noNeg > 3 || noZeros > 3)
                continue
            end
                        
            flag=0;
            same=diff(sort(ANSWE(:)));
            for n=1:splits-1
                if(same(n)>1)
                    flag=1;
                    break
                end
            end
            if flag==0 && noNeg==0 && noZeros==0
                fprintf('%s - The products are all same\n',fname);
                break
            elseif(noNeg==1 && flag==1)
                toprint=temp;
                printflag=1;
                printsplits=splits;
                fprintf('%s - xMisplaced at %d\n ',fname,temp);
                break
            end      
        end  
        if(printflag==1)
            wrong=cat(2,wrong,dirImage(i).name);
            copyfile (strcat(folder,'/',dirImage(i).name),'wrong')
            figure;
            imshow(A);
            hold on;
            fprintf('dim --> %d, %d, %d, %d\n',printsplits,toprint,x,y);
            rectangle('Position',[(y/printsplits)*(toprint-1),0,y/printsplits,x],...
                       'Curvature',[0.99,0.99],...
                       'LineWidth',2,'LineStyle','--',...
                       'EdgeColor','cyan')
            title(fname);
        end
    end
    if(printflag==0 && fileflag==1)
        correct=cat(2,correct,dirImage(i).name);
        copyfile (strcat(folder,'/',dirImage(i).name),'correct')
    end
end

execTime=toc